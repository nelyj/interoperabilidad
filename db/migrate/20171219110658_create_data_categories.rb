class CreateDataCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :data_categories do |t|

      t.timestamps
    end
  end
end
