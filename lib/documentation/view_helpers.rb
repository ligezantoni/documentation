module Documentation
  module ViewHelpers

    #
    # Path to edit a page in the manager UI
    #
    def documentation_edit_page_path(version, page)
      "#{::Documentation::Engine.mounted_path}/v/#{version.ordinal}/edit/#{page.full_permalink}"
    end

    #
    # Path to view a page in the manager UI
    #
    def documentation_page_path(version, page)
      "#{::Documentation::Engine.mounted_path}/v/#{version.ordinal}/#{page.try(:full_permalink)}"
    end

    #
    # Return a breadcrumb for the given page
    #
    def documentation_breadcrumb_for(version, page, options = {})
      options[:root_link] = options[:root_link].nil? ? t('documentation.helpers.documentation_breadcrumb_for.default_root_link', ordinal: version.ordinal) : options[:root_link]
      options[:class]     ||= 'breadcrumb'

      String.new.tap do |s|
        s << "<nav class='#{options[:class]}'><ul>"

        if options[:root_link]
          s << "<li><a href='#{documentation_doc_root.blank? ? '/' : documentation_doc_root}/v/#{version.ordinal}'>#{options[:root_link]}</a></li>"
        end

        if page.is_a?(::Documentation::Page)
          page.breadcrumb.each do |child|
            s << "<li><a href='#{documentation_doc_root}/v/#{version.ordinal}/#{child.full_permalink}'>#{child.title}</a></li>"
          end
        end

        s << "</ul></nav>"
      end.html_safe
    end

    #
    # Return a default navigation tree for the given page
    #
    def documentation_navigation_tree_for(version, page, options = {})
      locale = options[:locale] || I18n.locale
      active_page_type = nil
      items = String.new.tap do |s|
        if page.is_a?(::Documentation::Page)

          pages = page.navigation.select { |p,c| documentation_authorizer.can_view_page?(p) && p.version_id == version.id && p.locale.to_sym == locale }

          pages.each do |p, children|
            s << "<li>"
            s << "<a #{page == p ? "class='active'" : ''} href='#{documentation_doc_root}/v/#{version.ordinal}/#{p.full_permalink}'>#{p.title}</a>"
            active_page_type = :root if page == p
            unless children.empty?
              s << "<ul>"
              children.select { |c| documentation_authorizer.can_view_page?(c) }.each do |p|
                s << "<li><a #{page == p ? "class='active'" : ''} href='#{documentation_doc_root}/v/#{version.ordinal}/#{p.full_permalink}'>#{p.title}</a></li>"
                active_page_type = :child if page == p
              end
              s << "</ul>"
            end
            s << "</li>"
          end
        else
          ::Documentation::Page.roots.in_version(version.id).localized(locale).select { |p| documentation_authorizer.can_view_page?(p) }.each do |page|
            s << "<li><a href='#{documentation_doc_root}/v/#{version.ordinal}/#{page.full_permalink}'>#{page.title}</a></li>"
          end
        end
      end

      String.new.tap do |output|
        output << "<ul>"
        if options[:include_back] && page && page.breadcrumb.size > 1
          if active_page_type == :root && page.has_children?
            back_page = page.breadcrumb[-2]
          elsif active_page_type == :child && !page.has_children?
            back_page = page.breadcrumb[-3]
          else
            back_page = nil
          end

          if back_page
            output << "<li class='back'><a href='#{documentation_doc_root}/v/#{version.ordinal}/#{back_page.full_permalink}'>&larr; Back to #{back_page.title}</a></li>"
          end
        end
        output << items
        output << "</ul>"
      end.html_safe
    end

    #
    # Return appropriate content for a given page
    #
    def documentation_content_for(version, page)
      # Get the content
      content = page.compiled_content.to_s

      # Insert navigation
      content.gsub!("<p class=''>{{nav}}</p>") do
        children = page.children
        children = children.select { |c| documentation_authorizer.can_view_page?(c) }
        items = children.map { |c| "<li><a href='#{documentation_doc_root}/v/#{version.ordinal}/#{c.full_permalink}'>#{c.title}</a></li>" }.join
        "<ul class='pages'>#{items}</ul>"
      end

      # Set the document root as appropriate
      content.gsub!("{{docRoot}}", documentation_doc_root)

      # Return HTML safe content
      content.html_safe
    end

    #
    # Return the documentation document root
    #
    def documentation_doc_root
      @documentation_doc_root ||= begin
        if controller.is_a?(Documentation::ApplicationController)
          ::Documentation::Engine.mounted_path.to_s.sub(/\/$/, '')
        else
          ::Documentation.config.preview_path_prefix.to_s.sub(/\/$/, '')
        end
      end
    end

    #
    # Return the documentation authorizer
    #
    def documentation_authorizer
      @documentation_authorizer ||= Documentation.config.authorizer.new(controller)
    end

    #
    # Return summary information for search results
    #
    def documentation_search_summary(result)
      t('documentation.helpers.documentation_search_summary.text', :total_results => result.total_results, :start_result => result.start_result_number, :end_result => result.end_result_number, :query => result.query)
    end

    #
    # Return the search results
    #
    def documentation_search_results(version, result, options = {})
      options[:class] ||= 'searchResults'
      String.new.tap do |s|
        s << "<ul class='#{options[:class]}'>"
        result.results.each do |page|
          if documentation_authorizer.can_view_page?(page)
            s << "<li>"
            s << "<h4><a href='#{documentation_doc_root}/v/#{version.ordinal}/#{page.full_permalink}'>#{page.title}</a></h4>"
            unless page.parents.empty?
              s << "<p class='in'>#{t('documentation.helpers.documentation_search_results.in')} "
              s << page.parents.map { |c| link_to(h(c.title), "#{documentation_doc_root}/v/#{version.ordinal}/#{c.full_permalink}")}.join(" &#8658; ").html_safe
              s << "</p>"
            end
            s << "<p class='excerpt'>#{result.excerpt_for(page)}</p>"
            s << "</li>"
          end
        end
        s << "</ul>"
      end.html_safe
    end

    #
    # Return search pagination links
    #
    def documentation_search_pagination(version, result, options = {})
      String.new.tap do |s|
        unless result.first_page?
          querystring = {:query => result.query, :page => result.page - 1}.to_query
          s << link_to(t('documentation.helpers.documentation_search_pagination.previous'), "#{documentation_doc_root}/v/#{version.ordinal}/search?#{querystring}", :class => [options[:link_class], options[:previous_link_class]].compact.join(' '))
        end

        unless result.last_page?
          querystring = {:query => result.query, :page => result.page + 1}.to_query
          s << link_to(t('documentation.helpers.documentation_search_pagination.next'), "#{documentation_doc_root}/v/#{version.ordinal}/search?#{querystring}", :class => [options[:link_class], options[:next_link_class]].compact.join(' '))
        end
      end.html_safe
    end
    
    #
    # Returns all versions as options for select
    #
    def documentation_version_options(selected_value = nil)
      options_for_select(Documentation::Version.ordered.map(&:ordinal), selected_value)
    end

    #
    # Returns all available languages as options for select
    #
    def languages_options(app_locales, options = {})
      selected = options[:selected]
      options_for_select(app_locales.map { |locale| [t("languages.#{locale}"), locale] }, selected)
    end

  end
end
