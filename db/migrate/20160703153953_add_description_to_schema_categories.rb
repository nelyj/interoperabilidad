class AddDescriptionToSchemaCategories < ActiveRecord::Migration[5.0]
  def up
    add_column :schema_categories, :description, :string
    execute "UPDATE schema_categories SET description = name"
  end

  def down
    remove_column :schema_categories, :description
  end
end
