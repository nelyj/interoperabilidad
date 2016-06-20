class AddHumanizedNameToSchemas < ActiveRecord::Migration[5.0]
  def change
    add_column :schemas, :humanized_name, :string
  end
end
