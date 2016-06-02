class CreateSchemaCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :schema_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
