module Documentation
  class LanguagesController < ApplicationController

    skip_before_filter :set_version

    def set_language
      I18n.locale = params[:locale]
      redirect_to :back
    end

  end
end