module Documentation
  class Page < ActiveRecord::Base

    validates :title, :presence => true
    validates :position, :presence => true
    validates :permalink, :presence => true, :uniqueness => {:scope => [:parent_id, :version_id, :locale]}

    default_scope -> { order(:position) }
    scope :roots, -> { where(:parent_id => nil) }
    scope :in_version, -> (version_id) { where(:version_id => version_id) }
    scope :localized, -> (locale) { where(:locale => locale) }

    parent_options = {:class_name => "Documentation::Page", :foreign_key => 'parent_id'}
    parent_options[:optional] = true if ActiveRecord::VERSION::MAJOR >= 5
    belongs_to :parent, parent_options

    version_options = {:class_name => "Documentation::Version"}
    belongs_to :version, version_options

    before_validation do
      if self.position.blank?
        last_position = self.class.unscoped.where(:parent_id => self.parent_id).order(:position => :desc).first
        self.position = last_position ? last_position.position + 1 : 1
      end
    end

    before_validation :set_version
    before_validation :set_permalink
    before_save :compile_content

    #
    # Ensure the page is updated in the index after saving/destruction
    #
    after_commit :index, :on => [:create, :update]
    after_commit :delete_from_index, :on => :destroy

    #
    # Store all the parents of this object. THis is automatically populated when it is loaded
    # from a path
    #
    attr_accessor :parents

    #
    # Set the permalink for this page
    #
    def set_permalink
      return if self.title.blank?
      proposed_permalink = self.title.parameterize
      index = 1
      while self.permalink.blank?
        if self.class.where(:permalink => proposed_permalink, :parent_id => self.parent_id, :version_id => self.version_id).exists?
          index += 1
          proposed_permalink = self.title.parameterize + "-#{index}"
        else
          self.permalink = proposed_permalink
        end
      end
    end

    #
    # Set the version for this page
    #
    def set_version
      return if self.version_id.present?
      parent_record = self.class.unscoped.where(:id => self.parent_id).first if self.parent_id.present?
      self.version_id = parent_record&.version_id
    end

    #
    # Return a default empty array for parents
    #
    def parents
      @parents ||= self.parent ? [self.parent.parents, self.parent].flatten : []
    end

    #
    # Return a full breadcrumb to this page (as it has been loaded)
    #
    def breadcrumb
      @breadcrumb ||= [parents, new_record? ? nil : self].flatten.compact
    end

    #
    # Return the path where this page can be viewed in the site
    #
    def preview_path
      if path = Documentation.config.preview_path_prefix
        "#{path}#{full_permalink}"
      else
        nil
      end
    end

    #
    # Return a full permalink tot his page
    #
    def full_permalink
      @full_permalink ||= begin
        if parents.empty?
          self.permalink
        else
          previous = breadcrumb.compact.map(&:permalink).compact
          previous.empty? ? self.permalink : previous.join('/')
        end
      end
    end

    #
    # Return all child pages
    #
    def children
      @children ||= begin
        if self.new_record?
          self.class.none
        else
          children = self.class.where(:parent_id => self.id)
          children.each { |c| c.parents = [parents, self].flatten }
          children
        end
      end
    end

    #
    # Does this page have children?
    #
    def has_children?
      !children.empty?
    end

    #
    # Return pages which should be included in the navigation
    #
    def navigation
      if has_children?
        root_parent = parents[-1]
        if root_parent.nil?
          pages = self.class.roots.localized(I18n.locale)
        else
          pages = (root_parent || self).children
        end
      else
        root_parent = parents[-2] || parents[-1]
        if root_parent.nil? || (root_parent.parent.nil? && parents.size <= 1)
          pages = self.class.roots.localized(I18n.locale)
        else
          pages = (root_parent || self).children
        end
      end


      pages.map do |c|
        child_pages = []
        child_pages = c.children if breadcrumb.include?(c)
        [c, child_pages]
      end
    end

    #
    # Create the compiled content
    #
    def compile_content
      mr = Documentation::MarkdownRenderer.new(:with_toc_data => true)
      mr.page = self
      rc = Redcarpet::Markdown.new(mr, :space_after_headers => true, :fenced_code_blocks => true, :no_intra_emphasis => true, :highlight => true)
      self.compiled_content = rc.render(self.content.to_s).html_safe
    end

    #
    # Index this page
    #
    def index
      if searcher = Documentation.config.searcher
        searcher.index(self)
      end
    end

    #
    # Delete this page from the index
    #
    def delete_from_index
      if searcher = Documentation.config.searcher
        searcher.delete(self)
      end
    end

    #
    # Find a page using the searcher if one exists otherwise just fall back to AR
    # searching. Returns a Documentation::SearchResult object.
    #
    def self.search(query, options = {})
      if searcher = Documentation.config.searcher
        searcher.search(query, options)
      end
    end

    #
    # Find a page by passing a path to the page from the root of the
    # site
    #
    def self.find_from_path(version_id, path_string, options = {})
      raise ActiveRecord::RecordNotFound, "Couldn't find page without a path" if path_string.blank?
      locale = options[:locale] || I18n.locale
      path_parts = path_string.split('/')
      path = []
      path_parts.each_with_index do |p, i|
        page = self.where(:parent_id => (path.last ? path.last.id : nil), :version_id => version_id, :locale => locale).find_by_permalink(p)
        if page
          page.parents = path.dup
          page.parent = path.last
          path << page
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find page at #{path_string}"
        end
      end
      path.last
    end

    #
    # Reorder pages
    #
    def self.reorder(parent, order = [])
      order = order.map(&:to_i)
      order = self.where(:parent_id => parent.id).map(&:id) if order.empty?
      order.each_with_index do |id, index|
        command = self.find_by_id!(id)
        command.position = index + 1
        command.save
      end
    end

    #
    # Duplicates page for other versions
    #
    def self.duplicate(base_page, options = {})
      duplicate_page = base_page.dup
      duplicate_page.assign_attributes(options)
      duplicate_page.save

      if base_page.has_children?
        base_page.children.each do |child_page|
          duplicate(child_page, options.tap { |opts| opts[:parent] = duplicate_page})
        end
      end
    end

  end
end
