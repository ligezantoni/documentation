module Documentation
  class VersionLocalesController < Documentation::ApplicationController

    skip_before_filter :set_version
    before_filter :find_version, :only => [:new]

    def new
      authorizer.check! :add_version


      if request.patch?
        @version.validate_new_locale(safe_params, @application_locales)

        if @version.errors.empty?
          @version.new_locale(safe_params[:base_locale], safe_params[:locale_added])

          redirect_to versions_path, :notice => t('.notice')
        else
          render :action => "form"
        end
        return
      end
      render :action => "form"
    end

    private

    def find_version
      if params[:id]
        @version = Version.find(params[:id])
      end
    end

    def safe_params
      params.require(:version).permit(:base_locale, :locale_added)
    end

  end
end
