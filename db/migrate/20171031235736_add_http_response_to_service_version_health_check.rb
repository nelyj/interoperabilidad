class AddHttpResponseToServiceVersionHealthCheck < ActiveRecord::Migration[5.0]
  def change
    add_column :service_version_health_checks, :http_response, :text
  end
end
