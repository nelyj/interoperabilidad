class AddSchemaFlagToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :can_create_schemas, :boolean, default: false, null: false
  end
end
