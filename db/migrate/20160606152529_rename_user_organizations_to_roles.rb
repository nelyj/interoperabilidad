class RenameUserOrganizationsToRoles < ActiveRecord::Migration[5.0]
  def change
    rename_table :users_organizations, :roles
  end
end
