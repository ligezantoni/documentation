module Documentation
  class Backup

    require 'fileutils'

    def extract!
      puts 'Serializing pages...'
      serialized_pages = serialize_pages(Documentation::Page.joins(:version).all)
      
      puts 'Serializing images...'
      serialized_images = serialize_images(
        Nifty::Attachments::Attachment.where(parent_type: 'Documentation::Screenshot').includes(:parent)
      )

      puts 'Saving to file...'
      save_to_file!(serialized_pages, serialized_images)

      puts 'Done!'
    end

    def insert!
      puts 'Loading stored data...'
      serialized_pages = YAML.load(File.open(pages_store_path))
      serialized_images = YAML.load(File.open(images_store_path))

      puts 'Inserting pages...'
      insert_pages!(serialized_pages)

      puts 'Inserting images...'
      insert_images!(serialized_images)

      puts 'Done!'
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
        hash.merge!('children' => build_pages_tree(page.children)) if page.children.any?
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
    end

    def insert_pages!(pages)
      pages.each do |ordinal, version_pages|
        version = Documentation::Version.create(ordinal: ordinal)
        version_pages.each do |locale, locale_pages|
          insert_children!(version, locale_pages, locale)
        end
      end
    end

    def insert_images!(images)
      images.each do |_id, attributes|
        screenshot = Documentation::Screenshot.create(alt_text: attributes['alt_text'])
        screenshot.create_upload(
          token: attributes['token'],
          digest: attributes['digest'],
          file_name: attributes['file_name'],
          file_type: attributes['file_type'],
          data: attributes['data']
        )
      end
    end

    def insert_children!(version, pages_hash, locale, parent = nil)
      pages_hash.each do |permalink, attributes|
        parent_relation = parent.nil? ? version.pages : parent.children
        page = parent_relation.create(
          permalink: permalink,
          title: attributes['title'],
          content: attributes['content'],
          locale: locale
        )
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

  end
end