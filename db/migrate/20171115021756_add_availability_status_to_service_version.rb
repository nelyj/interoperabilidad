class AddAvailabilityStatusToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :availability_status, :integer, default: 0
  end
end
