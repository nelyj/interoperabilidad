class RemoveDefaultUserIdFromServiceVersion < ActiveRecord::Migration[5.0]
  def up
    change_column_default :service_versions, :user_id, nil
  end

  def down
    change_column_default :service_versions, :user_id, User.first.id
  end
end
