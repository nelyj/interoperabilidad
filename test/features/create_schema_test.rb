require "test_helper"

class CreateSchemaTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    visit root_path
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('menu-new-schema').click
    fill_in 'schema_name', :with => "Test"
    page.execute_script("$(\"input[type=file]\").show()")
  end

  test "attempt to create a schema without an attached file" do
    find('#create-schema').click
    assert_content page, "Expected type object but found type null"
  end

  test "attempt to create a schema with an invalid file" do
    attach_file 'schema_spec_file', Rails.root.join('README.md')
    find('#create-schema').click
    assert_content page, "Archivo no está en formato JSON o YAML:"
  end

  test "create a valid schema" do
    attach_file 'schema_spec_file', Rails.root.join(
      'test', 'files', 'test-schemas', 'schemaObject.json')
    find('#create-schema').click
    assert_content page, "schema was successfully created."
  end
end
