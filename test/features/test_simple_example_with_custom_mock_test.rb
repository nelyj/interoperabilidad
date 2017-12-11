require "test_helper"
require 'yaml'
require_relative 'support/ui_test_helper'

class TestSimpleExampleWithCustomMockTest < Capybara::Rails::TestCase
  include UITestHelper
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

  test "test custom mock in hello service" do

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'hello.yaml')

    swagger = YAML.load_file("#{Rails.root}/test/files/sample-services/hello.yaml")
    url_simple_example_host = swagger['schemes'].first + '://' + swagger['host']

    fill_in "service_custom_mock_service", with: url_simple_example_host

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    click_button "Probar Servicio"
    
    within ".console" do
      fill_in 'name', :with => "Mundo"

      select_test_with_mock_service('custom')

      click_button "Enviar"
      assert_content 'Respuesta'
      assert_content "Hola Mundo"
    end

  end

end
