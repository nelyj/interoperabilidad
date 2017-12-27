require "test_helper"
require_relative 'support/ui_test_helper'

class CreateNewSchemaVersionTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit schemas_path
    click_schema_category "Anotaciones"
    click_link "AnotacionesSchema1"
    click_link "Nueva Revisión"
    assert_content page, "Seleccionar Archivo"
    page.execute_script('$("input[type=file]").show()')
  end

  test "attempt to create a schema without an attached file" do
    click_button "Subir Nueva Revisión"
    assert_content page, "No se pudo crear nueva versión"
  end

  test "attempt to create a schema with an invalid file" do
    attach_file 'schema_version_spec_file', Rails.root.join('README.md')
    click_button "Subir Nueva Revisión"
    assert_content page, "Archivo no está en formato JSON o YAML"
  end

  test "create a valid schema" do
    attach_file 'schema_version_spec_file', Rails.root.join(
      'test', 'files', 'sample-schemas', 'schemaObject.json')
    click_button "Subir Nueva Revisión"
    assert_content page, "Nueva Versión creada correctamente"
  end

  test "create a valid schema with tags" do
    attach_file 'schema_version_spec_file', Rails.root.join(
      'test', 'files', 'sample-schemas', 'schemaObject.json')
    find_all('span[role="combobox"]').last.click
    find('li', text: data_categories(:some_other_tag).name).click
    click_button "Subir Nueva Revisión"
    assert_content page, "Nueva Versión creada correctamente"
    schema_version = Schema.find_by(name: 'AnotacionesSchema1').schema_versions.last
    assert_equal schema_version.schema.data_categories.map(&:name), [data_categories(:some_other_tag).name] 
  end
end
