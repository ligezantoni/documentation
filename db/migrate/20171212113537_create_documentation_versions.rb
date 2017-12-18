class CreateDocumentationVersions < ActiveRecord::Migration
  def change
    create_table :documentation_versions do |t|
      t.string :ordinal
      t.timestamps
    end
  end
end
