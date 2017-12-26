require "test_helper"
require_relative 'support/agreement_creation_helper'

class AgreementFlowTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test 'not loged user can not see Agreement Global View' do
    visit root_path
    assert has_no_field?('#user-menu')

    visit agreements_global_path
    assert_content('Para revisar los convenios de la plataforma por favor identifíquese con su clave única')

  end

  test 'non GobDigital User can not se Agreement Global View' do
    login_as users(:pedro), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      assert has_no_field?('#menu-vista-global-convenios')
    end

    visit agreements_global_path
    assert_content('No tiene permisos suficientes')
  end


  test 'GobDigital User can se Agreement Global View' do
    login_as users(:pablito), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      find('#menu-vista-global-convenios').click
    end

    assert_content('Vista Global de Convenios')
    assert_link ('Subir un convenio existente')
    assert find(:xpath, '//table/thead/tr').text.include?('Fecha de creación Institución proveedora Servicios Institución solicitante Estado Responsables Última modificación Fecha de Firma')

  end

end
