class AddPublicToService < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :public, :boolean, default: false
  end
end
