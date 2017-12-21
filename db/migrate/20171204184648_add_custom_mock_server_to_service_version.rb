class AddCustomMockServerToServiceVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :service_versions, :custom_mock_service, :string
  end
end
