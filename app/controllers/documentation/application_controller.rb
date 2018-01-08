module Documentation
  class ApplicationController < ActionController::Base

    rescue_from Documentation::AccessDeniedError do |e|
      flash[:alert] = t('documentation.alerts.access_denied')
      redirect_back
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      flash[:alert] = t('documentation.alerts.no_record')
      redirect_back
    end

    before_filter :set_locale
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
        @latest_version = Documentation::Version.last
        render :template => 'documentation/shared/choose_version'
      end
    end

    def set_locale
      @application_locales = I18n.available_locales & Documentation.config.available_locales
      session[:locale] = params[:locale] if params[:locale].present? && params[:locale].to_sym.in?(@application_locales)
      I18n.locale = session[:locale] || I18n.default_locale
    end

    def authorizer
      @authorizer ||= Documentation.config.authorizer.new(self)
    end

    def redirect_back(fallback_location: root_path(version_ordinal: @version&.ordinal))
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to fallback_location
    end

    helper_method :authorizer

  end
end
