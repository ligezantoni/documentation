module Documentation
  class VersionsController < Documentation::ApplicationController

    skip_before_filter :set_version
    before_filter :find_version, :only => [:edit, :destroy]

    def index
      @versions = Version.ordered
    end

    def new
      @version = Version.new
      authorizer.check! :add_version

      if request.post?
        @version.attributes = safe_params
        if @version.save
          redirect_to versions_path, :notice => t('.notice')
          return
        end
      end
      render :action => "form"
    end

    def edit
      authorizer.check! :edit_version, @version

      if request.patch?
        if @version.update_attributes(safe_params)
          redirect_to versions_path, :notice => t('.notice')
          return
        end
      end
      render :action => "form"
    end

    def destroy
      authorizer.check! :delete_version, @version
      @version.destroy
      redirect_to versions_path, :notice => t('.notice')
    end

    private

    def find_version
      if params[:id]
        @version = Version.find(params[:id])
      end
    end

    def safe_params
      params.require(:version).permit(:ordinal, :based_on)
    end

  end
end
