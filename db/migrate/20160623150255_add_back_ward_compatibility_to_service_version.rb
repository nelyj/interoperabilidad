class AddBackWardCompatibilityToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :backward_compatibility, :boolean, default: false, null: false
  end
end
