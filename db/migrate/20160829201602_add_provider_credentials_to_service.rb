class AddProviderCredentialsToService < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :provider_id, :string
    add_column :services, :provider_secret, :string
  end
end
