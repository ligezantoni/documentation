module Documentation
  class LanguagesController < ApplicationController

    skip_before_filter :set_version

    def set_language
      if params[:locale].present? && params[:locale].to_sym.in?(@application_locales)
        session[:locale] = params[:locale]
      else
        flash[:alert] = t('documentation.alerts.no_lang')
      end
      redirect_to :back
    end

  end
end