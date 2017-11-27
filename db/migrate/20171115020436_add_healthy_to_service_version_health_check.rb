class AddHealthyToServiceVersionHealthCheck < ActiveRecord::Migration[5.0]
  def change
    add_column :service_version_health_checks, :healthy, :boolean
  end
end
