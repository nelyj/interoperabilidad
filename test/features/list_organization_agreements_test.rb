require "test_helper"
require_relative 'support/ui_test_helper'

class ListOrganizationAgreementsTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def create_valid_service!
    service = Service.create!(
      organization: organizations(:sii),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:pedro))
    service
  end

  def create_valid_agreement!(orgp, orgc)
    service = create_valid_service!
    agreement = Agreement.create!(
      service_provider_organization: orgp,
      service_consumer_organization: orgc,
      user: users(:pedro),
      services: [service])
    agreement
  end

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
      assert find(:xpath, '//table/tbody/tr[1]').text.include?('Servicio de Impuestos Internos test-service')
    end
  end

end
