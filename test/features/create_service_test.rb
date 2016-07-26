require "test_helper"

class CreateServiceTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('services').click
    find_link('Crear Servicio').click
    fill_in 'service_name', :with => "Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "Attempt to create a service without an attached file" do
    click_button "Crear Servicio"
    assert_content page, "No se pudo crear el servicio"
  end

  test "Attempt to create a service with an invalid file" do
    attach_file 'service_spec_file', Rails.root.join('README.md')
    click_button "Crear Servicio"
    assert_content page, "Spec file Archivo no está en formato JSON o YAML"
  end

  test "Create a valid service" do
    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'petsfull.yaml')
    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"
  end
end
