class CreateSchemaDataCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_data_categories do |t|
      t.integer :schema_id
      t.integer :data_category_id
      t.timestamps
    end

    add_foreign_key :schema_data_categories, :schemas
    add_foreign_key :schema_data_categories, :data_categories
  end
end
