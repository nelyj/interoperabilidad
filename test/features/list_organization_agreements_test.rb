require "test_helper"
require_relative 'support/ui_test_helper'
require_relative 'support/agreement_creation_helper'

class ListOrganizationAgreementsTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "List Organization Provider Agreements" do
    login_as users(:pedro), scope: :user
    create_valid_agreement!(organizations(:sii), organizations(:segpres))
    visit root_path
    find('#user-menu').click
    within '#user-menu' do
      find('#agreements').click
    end
    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      assert_text find('li.active')[:text], 'Proveedor'
    end
    within '#proveedor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución solicitante Servicios involucrados Propósito Fecha ult. movimiento Estado')
      assert find(:xpath, '//table/tbody/tr[1]').text.include?('Secretaría General de la Presidencia test-service')
    end
  end

  test "List Organization Consumer Agreements" do
    login_as users(:pedro), scope: :user
    create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit root_path
    find('#user-menu').click
    within '#user-menu' do
      find('#agreements').click
    end
    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      find(:xpath, 'li[2]').click
      assert_text find('li.active')[:text], 'Consumidor'
    end
    within '#consumidor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
      assert find(:xpath, '//table/tbody/tr[1]').text.include?('Secretaría General de la Presidencia test-service')
    end
  end

end
