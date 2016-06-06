class AddIndexToSchema < ActiveRecord::Migration[5.0]
  def change
    add_index :schemas, :name
  end
end
