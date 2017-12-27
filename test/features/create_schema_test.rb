require "test_helper"

class CreateSchemaTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('menu-new-schema').click
    fill_in 'schema_name', :with => "Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "attempt to create a schema without an attached file" do
    click_button "Crear Esquema"
    assert_content page, "No se pudo crear el esquema"
  end

  test "attempt to create a schema with an invalid file" do
    attach_file 'schema_spec_file', Rails.root.join('README.md')
    click_button "Crear Esquema"
    assert_content page, "Archivo no está en formato JSON o YAML"
  end

  test "create a valid schema" do
    attach_file 'schema_spec_file', Rails.root.join(
      'test', 'files', 'sample-schemas', 'schemaObject.json')
    click_button "Crear Esquema"
    assert_content page, "Nuevo Esquema creado correctamente"
  end

  test "create a valid schema with tags" do
    attach_file 'schema_spec_file', Rails.root.join(
      'test', 'files', 'sample-schemas', 'schemaObject.json')
    pseudo_select_element = find_all('span.selection span[role="combobox"]').last
    pseudo_select_element.click
    find('li', text: data_categories(:some_other_tag).name).click
    click_button 'Crear Esquema'
    assert_content page, "Nuevo Esquema creado correctamente"
    schema = Schema.find_by(name: 'SchemaObject')
    assert_equal schema.data_categories.map(&:name), [data_categories(:some_other_tag).name] 
  end
end
