class AddUserEmailToNotification < ActiveRecord::Migration[5.0]
  def change
    add_column :notifications, :email, :string
  end
end
