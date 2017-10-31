class CreateServiceVersionHealthChecks < ActiveRecord::Migration[5.0]
  def change
    create_table :service_version_health_checks do |t|
      t.references :service_version
      t.integer :http_status
      t.integer :status_code
      t.string :status_message
      t.string :custom_status_message

      t.timestamps
    end
  end
end
