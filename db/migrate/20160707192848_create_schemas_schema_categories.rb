class CreateSchemasSchemaCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_categories_schemas do |t|
      t.integer :schema_id
      t.integer :schema_category_id
    end
    execute <<-SQL
      INSERT INTO schema_categories_schemas(schema_id, schema_category_id)
      SELECT id, schema_category_id
      FROM schemas
    SQL
    add_foreign_key "schema_categories_schemas", "schema_categories"
    add_foreign_key "schema_categories_schemas", "schemas"
    remove_foreign_key "schemas", "schema_categories"
    remove_column "schemas", "schema_category_id"
  end
end
