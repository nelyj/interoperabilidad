require "test_helper"
require_relative 'support/ui_test_helper'

class CreateServiceTest < Capybara::Rails::TestCase
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

  test "Attempt to create a service with an invalid mock url" do
    fill_in "service_custom_mock_service", with: "ht:1234.567"
    click_button "Crear Servicio"
    assert_content "No se pudo crear el servicio"
    assert_content "Simulador de Servicio Dirección Inválida"
  end

  test "Create a valid service with custom mock url" do
    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'petsfull.yaml')
    fill_in "service_custom_mock_service", with: "http://hola.mundo"
    click_button "Crear Servicio"
    assert_content "Servicio creado correctamente"
    click_button "Probar Servicio"
    assert_content "Parámetros"

    select_test_with_mock_service('custom')

    assert_content 'Servicio Simulado Externo'

  end

  test "Default change log in service" do
    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'petsfull.yaml')
    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"
    assert_content page, "Cambios"
    assert_content page, "Servicio Creado"
  end


end
