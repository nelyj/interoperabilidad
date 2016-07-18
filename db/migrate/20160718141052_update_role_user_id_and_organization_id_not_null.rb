class UpdateRoleUserIdAndOrganizationIdNotNull < ActiveRecord::Migration[5.0]
  def up
    execute 'UPDATE roles SET user_id = (SELECT id FROM users LIMIT 1)'
    execute 'UPDATE roles SET organization_id = (SELECT id FROM organizations LIMIT 1)'
    change_column_null :roles, :user_id, false
    change_column_null :roles, :organization_id, false
  end

  def down
    change_column_null :roles, :user_id, true
    change_column_null :roles, :organization_id, true
  end
end
