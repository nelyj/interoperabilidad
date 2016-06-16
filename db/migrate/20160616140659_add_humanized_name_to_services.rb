class AddHumanizedNameToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :humanized_name, :string
  end
end
