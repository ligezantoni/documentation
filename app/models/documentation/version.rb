module Documentation
  class Version < ActiveRecord::Base

    attr_accessor :based_on, :base_locale, :locale_added

    validates :ordinal, :presence => true, :uniqueness => true

    scope :ordered, -> { order(ordinal: :desc) }

    has_many :pages, dependent: :delete_all

    after_create :build_pages

    def build_pages
      return if based_on.blank?
      self.class.find(based_on).pages.roots.each do |root_page|
        Page.duplicate(root_page, version: self)
      end
    end

    def available_locales
      pages.pluck('DISTINCT locale').sort
    end

    def new_locale(base, added)
      self.pages.roots.each do |root_page|
        Page.duplicate(root_page, locale: added)
      end
    end

    def validate_new_locale(params, app_locales)
      self.errors[:base_locale] << t('activerecord.errors.models.documentation/version.attributes.base_locale.blank') unless params[:base_locale].present?
      self.errors[:locale_added] << t('activerecord.errors.models.documentation/version.attributes.locale_added.blank') unless params[:locale_added].present?
      self.errors[:locale_added] << t('activerecord.errors.models.documentation/version.attributes.locale_added.in_available') unless params[:locale_added].to_sym.in?(app_locales)
    end
    
  end
end
