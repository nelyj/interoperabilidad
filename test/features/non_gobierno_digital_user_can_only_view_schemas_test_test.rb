require "test_helper"

class NonGobiernoDigitalUserCanOnlyViewSchemasTestTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "non gobierno digital user can view schemas" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit schema_schema_version_path(schema_version.schema, schema_version)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page, "RUT de una persona o empresa"
    refute_content page, "Nueva Versión"
    refute_content page, "Nuevo Esquema"
  end

  test "non gobierno digital user can't upload new schema version" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit new_schema_schema_version_path(schema_version.schema, schema_version)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page,"no tiene permisos suficientes"
    refute_content page, "Nueva Versión"
    refute_content page, "Nuevo Esquema"
  end

  test "non gobierno digital user can't create new schemas" do
    login_as users(:pedro), scope: :user
    schema_version = schema_versions(:rut_v1)
    visit new_schema_path(schema_version.schema, schema_version)
    find('#user-menu').click
    assert_content page, users(:pedro).name
    assert_content page, users(:pedro).organizations.take.name
    assert_content page,"no tiene permisos suficientes"
    refute_content page, "Nueva Versión"
    refute_content page, "Nuevo Esquema"
  end
end
