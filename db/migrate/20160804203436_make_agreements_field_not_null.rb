class MakeAgreementsFieldNotNull < ActiveRecord::Migration[5.0]
  def change

    change_column_null :agreements, :service_provider_organization_id, false
    change_column_null :agreements, :service_consumer_organization_id, false

    change_column_null :agreement_revisions_services, :agreement_revision_id, false
    change_column_null :agreement_revisions_services, :service_id, false

    change_column_null :agreement_revisions, :agreement_id, false
    change_column_null :agreement_revisions, :user_id, false

    change_column_default :agreement_revisions, :state, from: nil, to: 0

    change_column_null :agreement_revisions, :state, false
    change_column_null :agreement_revisions, :revision_number, false

  end
end
