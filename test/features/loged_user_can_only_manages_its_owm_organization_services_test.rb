require "test_helper"

class LogedUserCanOnlyManagesItsOwmOrganizationServicesTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "non gobierno digital user can view services" do
    login_as users(:pedro), scope: :user
    service_version = service_versions(:servicio1_v1)
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page, "servicio_1 R1"
    refute_content page, "Nueva Revisión"
    refute_content page, "Nuevo Servicio"
  end

  test "user can't upload new service to other organization" do
    login_as users(:pedro), scope: :user
    org = organizations(:segpres)
    visit new_organization_service_path(org)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page,"No tiene permisos suficientes"
    refute_content page, "Nueva Revisión"
    refute_content page, "Nuevo Servicio"
  end

  test "user can't create new services version to other organization" do
    login_as users(:pedro), scope: :user
    service = services(:servicio_1)
    visit new_organization_service_path(service.organization, service)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page,"No tiene permisos suficientes"
    refute_content page, "Nueva Revisión"
    refute_content page, "Nuevo Servicio"
  end
end
