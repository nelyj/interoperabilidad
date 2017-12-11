require "test_helper"
require_relative 'support/ui_test_helper'

class CreateNewServiceVersionTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    within '#user-menu' do
      click_link('Servicios')
    end
    page.find(:xpath, '//table/tbody/tr[1]').click
    assert_content ('servicio_1')
    click_link('Nueva Revisión')
    assert_content page, "Seleccionar Archivo"
    page.execute_script('$("input[type=file]").show()')
  end

  test "attempt to create a service without an attached file" do
    click_button "Subir Nueva Revisión"
    assert_content page, "No se pudo guardar la nueva revisión debido a 1 error"
  end

  test "attempt to create a service with an invalid file" do
    attach_file 'service_version_spec_file', Rails.root.join('README.md')
    click_button "Subir Nueva Revisión"
    assert_content page, "Archivo no está en formato JSON o YAML"
  end

  test "create a valid service" do
    attach_file 'service_version_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'petsfull.yaml')
    click_button "Subir Nueva Revisión"
    assert_content page, "Nueva revisión creada correctamente"
  end

  test "create a valid new version with custom mock url" do
    attach_file 'service_version_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'petsfull.yaml')
    fill_in "service_version_custom_mock_service", with: "http://hola.mundo"
    click_button "Subir Nueva Revisión"
    assert_content page, "Nueva revisión creada correctamente"
    click_button "Probar Servicio"
    assert_content "Parámetros"

    select_test_with_mock_service('custom')

    assert_content 'Servicio Simulado Externo'
  end

  test "Attempt to create a version with an invalid mock url" do
    fill_in "service_version_custom_mock_service", with: "ht:1234.567"
    click_button "Subir Nueva Revisión"
    assert_content "No se pudo guardar la nueva revisión debido a 2 errores"
    assert_content "Simulador de Servicio Dirección Inválida"
  end


end
