class CreateServiceDataCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :service_data_categories do |t|
      t.integer :service_id
      t.integer :data_category_id
      t.timestamps
    end
  end
end
