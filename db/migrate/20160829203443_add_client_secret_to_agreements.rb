class AddClientSecretToAgreements < ActiveRecord::Migration[5.0]
  def change
    add_column :agreements, :client_secret, :string
  end
end
