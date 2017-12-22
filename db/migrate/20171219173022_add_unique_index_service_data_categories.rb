class AddUniqueIndexServiceDataCategories < ActiveRecord::Migration[5.0]
  def change
    change_table :service_data_categories do |t|
      # The default index name is too long.
      t.index([:service_id, :data_category_id], unique: true, name: 'svc_data_cat_unique_svc_id_data_cat_id')
    end
  end
end
