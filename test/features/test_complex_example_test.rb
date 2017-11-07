require "test_helper"
require 'yaml'

class TestSimpleExampleTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('services').click
    find_link('Crear Servicio').click
    fill_in 'service_name', :with => "Compex Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "complex service example" do
    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'ComplexExample.yaml')

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    click_button "Probar Servicio"
    within ".console" do
      click_button "Enviar"
      assert_content 'pedro@dominio.com'
      assert_content 'Juan Andres'
      assert_content 'Perez Cortez'
    end

  end

end
