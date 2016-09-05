require 'test_helper'
require "#{Rails.root}/test/features/support/agreement_creation_helper"

class AgreementTest < ActiveSupport::TestCase
  include AgreementCreationHelper

  test 'New AgreementRevision is created when an Agreement is created' do
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert agreement.agreement_revisions.exists?
  end

  test '#last_revision_number returns the version number of the last agreement revision' do
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert_equal 1, agreement.last_revision_number
    agreement.agreement_revisions.create(user: users(:perico))
    assert_equal 2, agreement.last_revision_number
    agreement.agreement_revisions.create(user: users(:perico))
    assert_equal 3, agreement.last_revision_number
  end

  test '.user_can_update_agreement_status? returns true for user than can update status' do
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert agreement.user_can_update_agreement_status?(users(:pablito))
  end

  test '.user_can_update_agreement_status? return false for user that can\'t update status' do
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert_not agreement.user_can_update_agreement_status?(users(:pedro))
  end

  test 'agreement revision is deleted if Signer returns error' do
    consummer_user = users(:pablito)
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    file = "content.pdf"
    path = "#{Rails.root}/test/files/sample-pdf/"
    agreement.last_revision.upload_pdf(file, path+file)

    assert agreement.state == 'draft'
    assert agreement.last_revision.file.include?(file)

    agreement.validate_draft(consummer_user)
    assert agreement.state == 'validated_draft'

    file = agreement.last_revision.file
    agreement.sign_draft(consummer_user, '000000')
    assert agreement.state == 'validated_draft'
  end

  test 'agreement life cicle' do
    consummer_user = users(:pablito)
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    file = "content.pdf"
    path = "#{Rails.root}/test/files/sample-pdf/"
    agreement.last_revision.upload_pdf(file, path+file)

    assert agreement.state == 'draft'
    assert agreement.last_revision.file.include?(file)

    agreement.validate_draft(consummer_user)
    assert agreement.state == 'validated_draft'

    file = agreement.last_revision.file
    agreement.sign_draft(consummer_user, '000000')
    assert agreement.state == 'validated_draft'

    #This is necesary, because we can call signer on test (no way to input OTP)
    agreement.new_revision(consummer_user,"signed_draft","Manually Sign Draft","", file)
    assert agreement.state == "signed_draft"

    provider_user = users(:pedro)
    agreement.validate_revision(provider_user)
    assert agreement.state == "validated"

    file = agreement.last_revision.file
    agreement.sign(provider_user, '000000')
    assert agreement.state == 'validated'

    #This is necesary, because we can call signer on test (no way to input OTP)
    agreement.new_revision(provider_user,"signed","Manually Sign Draft","", file)
    assert agreement.state == "signed"
  end

  test '.active_organization_in_flow return service_consumer_organization' do
    consummer_user = users(:pablito)
    service_consumer_organization= organizations(:segpres)
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert agreement.state == 'draft'
    assert agreement.active_organization_in_flow.name.include?(service_consumer_organization.name)
  end

  test '.active_organization_in_flow return service_provider_organization' do
    provider_user = users(:pedro)
    service_provider_organization= organizations(:sii)
    agreement = create_valid_agreement!(organizations(:sii) , (organizations(:segpres)))
    assert agreement.state == 'draft'

    #This is necesary, because we can call signer on test (no way to input OTP)
    agreement.new_revision(provider_user,"signed","Manually Sign Draft","", "")
    assert agreement.state == "signed"

    assert agreement.active_organization_in_flow.name.include?(service_provider_organization.name)
  end

end
