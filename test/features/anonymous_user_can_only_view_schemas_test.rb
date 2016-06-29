require "test_helper"

class AnonymousUserCanOnlyViewSchemasTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "anonymous user can view schemas" do
    schema_version = schema_versions(:rut_v1)
    visit schema_schema_version_path(schema_version.schema, schema_version)
    assert page.has_content?("RUT de una persona o empresa")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "anonymous user can't upload new schema version" do
    schema_version = schema_versions(:rut_v1)
    visit new_schema_schema_version_path(schema_version.schema, schema_version)
    assert page.has_content?("Para subir un esquema por favor identifíquese con su clave única")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "anonymous user can't create new schemas" do
    schema_version = schema_versions(:rut_v1)
    visit root_path
    visit new_schema_schema_version_path(schema_version.schema, schema_version)
    assert page.has_content?("Para subir un esquema por favor identifíquese con su clave única")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end
end
