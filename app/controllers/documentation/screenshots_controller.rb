module Documentation
  class ScreenshotsController < Documentation::ApplicationController

    skip_before_filter :set_version
    before_filter :find_screenshot, :only => [:destroy]

    def index
      @screenshots = Screenshot.all #Nifty::Attachments::Attachment.all
    end

    def destroy
      authorizer.check! :delete_screenshot, @screenshot
      @screenshot.destroy
      redirect_to screenshots_path, :notice => t('.notice')
    end

    private

    def find_screenshot
      if params[:id]
        @screenshot = Screenshot.find(params[:id])
      end
    end

  end
end