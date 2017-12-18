module Documentation
  class ApplicationController < ActionController::Base

    rescue_from Documentation::AccessDeniedError do |e|
      redirect_to root_path(version_ordinal: @version.ordinal), :alert => t('documentation.alerts.access_denied')
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      redirect_to root_path(version_ordinal: @version.ordinal), :alert => t('documentation.alerts.no_record')
    end

    before_filter :set_version
    before_filter do
      unless authorizer.can_use_ui?
        render :template => 'documentation/shared/not_found', :layout => false
      end
    end

    private

    def set_version
      return if params[:version_ordinal] == 'versions'
      @version = Documentation::Version.find_by(ordinal: params[:version_ordinal])
      if @version.blank?
        @version = Documentation::Version.last
        redirect_to root_path(version_ordinal: @version.ordinal), :notice => t('documentation.notices.no_version')
      end
    end

    def authorizer
      @authorizer ||= Documentation.config.authorizer.new(self)
    end

    helper_method :authorizer

  end
end
