require 'documentation/authorizer'
require 'documentation/searchers/simple'

module Documentation

  #
  # Sets the default configuration
  #
  DEFAULT_CONFIGURATION = {
    # This defines the at path where a page can be viewed in
    # the source website. For example, /docs/
    :preview_path_prefix => nil,

    # Should we display developer tips in the UI?
    :developer_tips => true,

    # Should we display developer tips in the UI?
    :markdown_hints => true,

    # The authorizer to use
    :authorizer => Documentation::Authorizer,

    # The searcher to use
    :searcher => Documentation::Searchers::Simple.new,

    # Application name
    :app_name => '',

    # Available locales
    :available_locales => I18n.available_locales
}

  #
  # Return configuration options
  #
  def self.config
    @config ||= OpenStruct.new(DEFAULT_CONFIGURATION)
  end

end
