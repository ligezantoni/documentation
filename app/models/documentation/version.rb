module Documentation
  class Version < ActiveRecord::Base

    attr_accessor :based_on

    validates :ordinal, :presence => true, :uniqueness => true

    scope :ordered, -> { order(ordinal: :desc) }

    has_many :pages, dependent: :delete_all

    after_create :build_pages

    def build_pages
      return if based_on.nil?
      self.class.find(based_on).pages.each do |page|
        page.dup.tap { |p| p.version = self }.save
      end
    end
    
  end
end
