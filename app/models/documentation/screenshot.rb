module Documentation
  class Screenshot < ActiveRecord::Base

    attachment :upload

    before_validation do
      if self.upload_file && self.alt_text.blank?
        self.alt_text = self.upload_file.original_filename
      end
      true
    end

    has_one :upload, lambda { select { [:id, :token, :digest, :parent_id, :parent_type, :file_name, :file_type] }.where(:role => :upload) }, :class_name => 'Nifty::Attachments::Attachment', :as => :parent

    def untapped?
      @embedded ||= !Page.where('content LIKE ?', "%#{upload.path}%").any?
    end

  end
end
