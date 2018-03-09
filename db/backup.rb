module Documentation
  class Backup

    require 'fileutils'

    def extract!
      printf 'Serializing pages...'
      serialized_pages = serialize_pages(Documentation::Page.joins(:version).all)
      puts success_message("Done!")

      printf 'Serializing images...'
      serialized_images = serialize_images(
        Nifty::Attachments::Attachment.where(parent_type: 'Documentation::Screenshot').includes(:parent)
      )
      puts success_message("Done!")

      printf 'Saving to files...'
      save_to_file!(serialized_pages, serialized_images)
      puts success_message("Done!")

      puts success_message("Serialized docs saved_successfully.")
      puts "└ db/backup_docs\n\t├ pages.yml\n\t└ images.yml"
    rescue Errno::ENOENT => e
      puts error_message("\nError: Failed to save docs to files.")
    end

    def insert!
      printf 'Loading stored data...'
      serialized_pages = YAML.load(File.open(pages_store_path))
      serialized_images = YAML.load(File.open(images_store_path))
      puts success_message("Done!")

      printf 'Inserting pages...'
      insert_pages!(serialized_pages)
      puts success_message("Done!")

      printf 'Inserting images...'
      insert_images!(serialized_images)
      puts success_message("Done!")

      puts success_message("Docs inserted successfully.")
    rescue Errno::ENOENT => e
      puts error_message("\nError: No backup files found.")
      puts "Make sure you have proper file structure:\n└ db/backup_docs\n\t├ pages.yml\n\t└ images.yml"
    rescue ActiveRecord::RecordInvalid => e
      puts error_message("\nError: couldn't save record.")
    end
    private

    def serialize_pages(pages)
      pages.group_by(&:version_ordinal).each_with_object({}) do |(ordinal, version_pages), version_hash|
        grouped_locale_pages = version_pages.group_by(&:locale)
        version_hash[ordinal] = grouped_locale_pages.each_with_object({}) do |(locale, locale_pages), locale_hash|
          locale_hash[locale] = build_pages_tree(locale_pages.select(&:root?))
        end
      end
    end

    def build_pages_tree(root_pages)
      root_pages.each_with_object({}) do |page, hash|
        hash[page.permalink] = {
          'title' => page.title,
          'content' => page.content,
          'position' => page.position
        }
        hash[page.permalink].merge!('children' => build_pages_tree(page.children)) if page.children.any?
      end
    end

    def serialize_images(attachments)
      attachments.each_with_object({}) do |attachment, hash|
        hash[attachment.parent_id] = {
            'alt_text' => attachment.parent&.alt_text,
            'token' => attachment.token,
            'digest' => attachment.digest,
            'role' => attachment.role,
            'file_name' => attachment.file_name,
            'file_type' => attachment.file_type,
            'data' => attachment.data
        }
      end
    end

    def save_to_file!(pages, images)
      FileUtils.mkdir_p(store_directory) unless File.directory?(store_directory)
      File.write(pages_store_path, pages.to_yaml)
      File.write(images_store_path, images.to_yaml)
      raise Errno::ENOENT unless File.exists?(pages_store_path) | File.exists?(images_store_path)
    end

    def insert_pages!(pages)
      Documentation::Version.transaction do
        pages.each do |ordinal, version_pages|
          version = Documentation::Version.find_or_create_by(ordinal: ordinal)
          version_pages.each do |locale, locale_pages|
            insert_children!(version, locale_pages, locale)
          end
        end
      end
    end

    def insert_images!(images)
      Documentation::Screenshot.transaction do
        images.each do |_id, attributes|
          next if Nifty::Attachments::Attachment.where(token: attributes['token']).any?
          screenshot = Documentation::Screenshot.create(alt_text: attributes['alt_text'])
          screenshot.create_upload!(
              token: attributes['token'],
              digest: attributes['digest'],
              file_name: attributes['file_name'],
              file_type: attributes['file_type'],
              data: attributes['data']
          )
        end
      end
    end

    def insert_children!(version, pages_hash, locale, parent = nil)
      pages_hash.each do |permalink, attributes|
        parent_relation = parent.nil? ? version.pages : parent.children
        page = parent_relation.find_or_initialize_by(permalink: permalink)
        page.assign_attributes(
          title: attributes['title'],
          content: attributes['content'],
          locale: locale
        )
        page.save
        insert_children!(version, attributes['children'], locale, page) if attributes['children'].present?
      end
    end

    def store_directory
      @store_dir ||= Rails.root.join('db', 'backup_docs')
    end

    def pages_store_path
      @pages_path ||= File.join(store_directory, 'pages.yml')
    end

    def images_store_path
      @images_path ||= File.join(store_directory, 'images.yml')
    end

    def error_message(message)
      "\e[31m#{message}\e[0m"
    end

    def success_message(message)
      "\e[32m#{message}\e[0m"
    end

  end
end