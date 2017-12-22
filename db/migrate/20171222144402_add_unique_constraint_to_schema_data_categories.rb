class AddUniqueConstraintToSchemaDataCategories < ActiveRecord::Migration[5.0]
  def change
    change_table :schema_data_categories do |t|
      t.index([:schema_id, :data_category_id], unique: true)
    end
  end
end
