class AddFkToServiceDataCategory < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :service_data_categories, :services
    add_foreign_key :service_data_categories, :data_categories
  end
end
