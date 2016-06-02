class CreateSchemas < ActiveRecord::Migration[5.0]
  def change
    create_table :schemas do |t|
      t.string :name, null: false
      t.integer :schema_category_id, null: false

      t.timestamps
    end
    add_foreign_key :schemas, :schema_categories
  end
end
