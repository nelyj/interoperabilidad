require 'test_helper'

class AgreementTest < ActiveSupport::TestCase

  def create_valid_service!
    service = Service.create!(
      organization: organizations(:sii),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:perico))
    service
  end

  def create_valid_agreement!
    service = create_valid_service!
    agreement = Agreement.create!(
      service_provider_organization: organizations(:sii),
      service_consumer_organization: organizations(:segpres),
      user: users(:perico),
      services: [service])
    agreement
  end

  test 'New AgreementRevision is created when an Agreement is created' do
    agreement = create_valid_agreement!
    assert agreement.agreement_revisions.exists?
  end

  test '#last_revision_number returns the version number of the last agreement revision' do
    agreement = create_valid_agreement!
    assert_equal 1, agreement.last_revision_number
    agreement.agreement_revisions.create(user: users(:perico))
    assert_equal 2, agreement.last_revision_number
    agreement.agreement_revisions.create(user: users(:perico))
    assert_equal 3, agreement.last_revision_number
  end

end
