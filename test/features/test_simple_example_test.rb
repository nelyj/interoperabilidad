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
    fill_in 'service_name', :with => "Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "test hello service" do

    # TODO: Add external request mock
    skip("Skiped because use external rest service")

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'hello.yaml')

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    click_button "Probar Servicio"
    within ".console" do
      fill_in 'name', :with => "Mundo"
      click_button "Enviar"
      assert_content 'Respuesta'
      assert_content "Hola Mundo"
    end

  end

end
