require "test_helper"

class AnonymousUserCanOnlyViewServicesTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "anonymous user can view services" do
    service_version = service_versions(:servicio1_v3)
    visit organization_service_service_version_path(service_version.organization, service_version.service, service_version)
    assert page.has_content?("servicio_1 R3")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "anonymous user can't upload new service version" do
    service_version = service_versions(:servicio1_v3)
    visit new_organization_service_service_version_path(service_version.organization, service_version.service)
    assert page.has_content?("Para subir un esquema por favor identifíquese con su clave única")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "anonymous user can't create new services" do
    service_version = service_versions(:servicio1_v3)
    visit new_organization_service_path(service_version.organization)
    assert page.has_content?("Para subir un esquema por favor identifíquese con su clave única")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end
end
