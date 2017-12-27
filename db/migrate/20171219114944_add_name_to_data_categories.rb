class AddNameToDataCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :data_categories, :name, :string
  end
end
