require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceDetailTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:pedro))
  end

  test "Show service" do
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
    assert_content "Este servicio requiere un convenio activo para ser usado"
  end

  test "No Agreement button for public services" do
    users(:pablito).roles.create(organization: organizations(:segpres), name: "Create Agreement", email: "mail@example.org")
    @service_v.service.update!(public: true)
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_no_link "Solicitar Convenio"
    end
    assert_no_content "Este servicio requiere un convenio activo para ser usado"
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
    assert_no_content "Este servicio requiere un convenio activo para ser usado"
  end


  test "No Agreement button for User for another organization without Create Agreement role" do
    login_as( users(:pablito) )
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_no_link "Solicitar Convenio"
    end
    assert_content "Este servicio requiere un convenio activo para ser usado"
    assert_content "No tiene permisos suficientes para solicitar convenios"
  end

  test "No Agreement button when user is not logged in" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_content "PetsServiceName"
    within ".principal-actions" do
      assert_no_link "Solicitar Convenio"
    end
    assert_content "Este servicio requiere un convenio activo para ser usado"
    assert_content "Identifíquese con su clave única para solicitar un convenio"
  end

  test "Do not show tokens for private service if the user is not logged in" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_no_link "Tokens"
  end

  test "Do not show tokens for private service if the user belongs to a different org, regardless of their role there" do
    users(:pablito).roles.create(organization: organizations(:segpres), name: "Sign Agreement", email: "mail@example.org")
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_no_link "Tokens"
  end

  test "Show only client token for private service if the user belongs to the org but is not the creator of the service nor has any special role" do
    users(:pablito).roles.create(organization: organizations(:sii), name: "Create Agreement", email: "mail@example.org")
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_link "Tokens"
    click_link "Tokens"
    assert_content "Client Token"
    assert_no_content "Provider ID"
    assert_no_content "Provider Secret"
  end

  test "Show provider and client tokens for private service if the user has the Validate Agreement role" do
    users(:pablito).roles.create(organization: organizations(:sii), name: "Validate Agreement", email: "mail@example.org")
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_link "Tokens"
    click_link "Tokens"
    assert_content "Provider ID"
    assert_content "Provider Secret"
    assert_content "Client Token"
  end

  test "Show provider and client tokens for private service if the user has the Sign Agreement role" do
    users(:pablito).roles.create(organization: organizations(:sii), name: "Sign Agreement", email: "mail@example.org")
    login_as(users(:pablito))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_link "Tokens"
    click_link "Tokens"
    assert_content "Provider ID"
    assert_content "Provider Secret"
    assert_content "Client Token"
  end


  test "Show provider and client tokens for private service if the user is the creator of the service" do
    login_as(users(:pedro))
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    assert_link "Tokens"
    click_link "Tokens"
    assert_content "Provider ID"
    assert_content "Provider Secret"
    assert_content "Client Token"
  end
end
