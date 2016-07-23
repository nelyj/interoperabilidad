require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceDetail < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:minsal),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:pedro))
  end

  test "Show service " do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    assert_content "This is a sample server Petstore server."
    assert_content "For this sample, you can use the api key special-key to test the authorization filters"
    assert_link "Ver OAS"
    assert_button "Generar código fuente"
    assert_content "http://petstore.swagger.io/v2"
  end

  test "Agreement button for User for another organization and Role Create Agreement" do
    users(:pablito).roles.create(organization: organizations(:segpres), name: "Create Agreement", email: "mail@example.org")
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_link "Solicitar Convenio"
    end
  end

  test "No Agreement button for User for same organization" do
    login_as(users(:pedro))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_no_link "Solicitar Convenio"
    end
  end

  test "No Agreement button for User for another organization and Role Service Provider" do
    login_as( users(:pablito) )
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_no_link "Solicitar Convenio"
    end
  end

end
