class CreateAgreements < ActiveRecord::Migration[5.0]
  def change
    create_table :agreements do |t|
      t.references :service_provider_organization
      t.references :service_consumer_organization
    end
    add_reference :organizations, :agreements
  end
end
