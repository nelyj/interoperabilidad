require "test_helper"

class NonGobiernoDigitalUserCanOnlyViewSchemasTestTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "non gobierno digital user can view schemas" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit schema_schema_version_path(schema_version.schema, schema_version)
    assert page.has_content?(users(:pedro).name)
    assert page.has_content?(users(:pedro).organizations.take.name)
    assert page.has_content?("RUT de una persona o empresa")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "non gobierno digital user can't upload new schema version" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit new_schema_schema_version_path(schema_version.schema, schema_version)
    assert page.has_content?(users(:pedro).name)
    assert page.has_content?(users(:pedro).organizations.take.name)
    assert page.has_content?("no tiene permisos suficientes")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end

  test "non gobierno digital user can't create new schemas" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit new_schema_path(schema_version.schema, schema_version)
    assert page.has_content?(users(:pedro).name)
    assert page.has_content?(users(:pedro).organizations.take.name)
    assert page.has_content?("no tiene permisos suficientes")
    assert page.has_no_content?("Nueva Versión")
    assert page.has_no_content?("Nuevo Esquema")
  end
end
