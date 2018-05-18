module Documentation
  class PagesController < Documentation::ApplicationController

    before_filter :find_page, :only => [:show, :edit, :new, :destroy, :positioning]

    def show
      authorizer.check! :view_page, @page
    end

    def edit
      authorizer.check! :edit_page, @page

      if request.patch?
        if @page.update_attributes(safe_params)
          redirect_to page_path(@page.full_permalink, version_ordinal: @version.ordinal), :notice => t('.notice')
          return
        end
      end
      render :action => "form"
    end

    def new
      authorizer.check! :add_page, @page

      parent = @page
      @page = Page.new(:version_id => @version.id, :locale => I18n.locale)
      if @page.parent = parent
        @page.parents = parent.breadcrumb
      end

      if request.post?
        @page.attributes = safe_params
        if @page.save
          redirect_to page_path(@page.full_permalink, version_ordinal: @version.ordinal), :notice => t('.notice')
          return
        end
      end
      render :action => "form"
    end

    def destroy
      authorizer.check! :delete_page, @page
      @page.destroy
      if params[:redirect_to].present?
        redirect_to params[:redirect_to].to_sym, :notice => t('.notice')
      else
        redirect_to @page.parent ? page_path(@page.parent.full_permalink, version_ordinal: @version.ordinal) : root_path, :notice => t('.notice')
      end
    end

    def screenshot
      authorizer.check! :upload, @page
      if request.post?
        @screenshot = Screenshot.new(screenshot_params)
        if @screenshot.save
          render :json => { :id => @screenshot.id, :title => @screenshot.alt_text, :path => @screenshot.upload.path }, :status => :created
        else
          render :json => { :errors => @screenshot.errors }, :status => :unprocessible_entity
        end
      else
        @screenshot = Screenshot.new
        render 'screenshot', :layout => false
      end
    end

    def positioning
      authorizer.check! :reposition_page, @page
      @pages = @page ? @page.children : Page.roots.in_version(@version.id).localized(I18n.locale)
      if request.post?
        Page.reorder(@page, params[:order])
        render :json => {:status => 'ok'}
      end
    end

    def search
      authorizer.check! :search
      @result = Documentation::Page.in_version(@version.id).search(params[:query], :page => params[:page].blank? ? 1 : params[:page].to_i) #, per_page: 20)
    end

    private

    def find_page
      if params[:path]
        @page = Page.find_from_path(@version.id, params[:path], locale: I18n.locale)
      end
    end

    def safe_params
      params.require(:page).permit(:title, :permalink, :content, :favourite)
    end

    def screenshot_params
      params.require(:screenshot).permit(:upload_file, :alt_text)
    end

  end
end
