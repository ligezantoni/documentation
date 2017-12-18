class CreateDocumentationPages < ActiveRecord::Migration
  def up
    create_table "documentation_pages" do |t|
      t.string :title, :permalink
      t.text :content, :compiled_content
      t.integer :parent_id, :position, :version_id
      t.timestamps
    end
  end

  def down
    drop_table :documentation_pages
  end
end
