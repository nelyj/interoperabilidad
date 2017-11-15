require 'test_helper'
require_relative '../features/support/agreement_creation_helper'

class ServicesControllerTest < ActionDispatch::IntegrationTest
  include AgreementCreationHelper
  include Warden::Test::Helpers

  test "exchange client id+secret for a client token using params" do
    agreement = create_valid_agreement!(organizations(:sii), organizations(:segpres))
    agreement.new_revision(users(:pedro),"signed","Manually Signed","", "file")
    post(
      organization_service_oauth_token_path(
        agreement.service_provider_organization,
        agreement.services.first
      ),
      params: {
        grant_type: 'client_credentials',
        client_id: agreement.id,
        client_secret: agreement.client_secret
      }
    )
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert json_response.has_key? 'access_token'
    assert json_response.has_key? 'expires_in'
    assert_equal 'bearer', json_response['token_type']
  end

  test "exchange client id+secret for a client token authentication header" do
    agreement = create_valid_agreement!(organizations(:sii), organizations(:segpres))
    agreement.new_revision(users(:pedro),"signed","Manually Signed","", "file")
    auth = Base64.encode64("#{agreement.id}:#{agreement.client_secret}")
    post(
      organization_service_oauth_token_path(
        agreement.service_provider_organization,
        agreement.services.first
      ),
      params: {
        grant_type: 'client_credentials',
      },
      headers: {
        Authorization: "Basic #{auth}"
      }
    )
    assert_response :success
    json_response = JSON.parse(@response.body)
    assert json_response.has_key? 'access_token'
    assert json_response.has_key? 'expires_in'
    assert_equal 'bearer', json_response['token_type']
  end


  test "exchange client id+secret for a client token with wrong secret" do
    agreement = create_valid_agreement!(organizations(:sii), organizations(:segpres))
    agreement.new_revision(users(:pedro),"signed","Manually Signed","", "file")
    post(
      organization_service_oauth_token_path(
        agreement.service_provider_organization,
        agreement.services.first
      ),
      params: {
        grant_type: 'client_credentials',
        client_id: agreement.id,
        client_secret: agreement.client_secret + 'blah'
      }
    )
    assert_response 400
    json_response = JSON.parse(@response.body)
    assert_equal 'Invalid Client ID or Client Secret', json_response['error_description']
    assert_equal 'invalid_client', json_response['error']
  end

  test "exchange client id+secret for a client token with wrong id" do
    agreement = create_valid_agreement!(organizations(:sii), organizations(:segpres))
    # Hack to set the agreement as signed:
    agreement.new_revision(users(:pedro),"signed","Manually Signed","", "file")
    post(
      organization_service_oauth_token_path(
        agreement.service_provider_organization,
        agreement.services.first
      ),
      params: {
        grant_type: 'client_credentials',
        client_id: agreement.id + 1,
        client_secret: agreement.client_secret
      }
    )
    assert_response 400
    json_response = JSON.parse(@response.body)
    assert_equal 'Invalid Client ID or Client Secret', json_response['error_description']
    assert_equal 'invalid_client', json_response['error']
  end

  test "rollback service create on version error" do
    pedro = users(:pedro)
    login_as pedro
    organization = pedro.organizations.first

    file = Rack::Test::UploadedFile.new("#{Rails.root}/test/files/sample-services/hello.yaml")

    # mock = MiniTest::Mock.new
    raises_exception = -> { raise "exception test" }
    # mock.expect :create_first_version, raises_exception

    Service.stub_any_instance :create_first_version, raises_exception do
      post(
        organization_services_path(organization), 
        params: {
          service: {
            name: 'test-service'+SecureRandom.uuid,
            spec_file: file,
            backwards_compatible: true,
            organization_id: organization.id
          }
        })
      assert_response 302
      assert_equal Service.count, 2

    end

  end

end
