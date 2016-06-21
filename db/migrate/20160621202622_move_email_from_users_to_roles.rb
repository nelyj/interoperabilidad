class MoveEmailFromUsersToRoles < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :email, :string
    add_column :roles, :email, :string
  end
end
