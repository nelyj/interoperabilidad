class AddMonitoringEnabledToService < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :monitoring_enabled, :boolean, default: true
  end
end
