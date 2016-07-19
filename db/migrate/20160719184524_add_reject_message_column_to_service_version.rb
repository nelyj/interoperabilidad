class AddRejectMessageColumnToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :reject_message, :text
  end
end
