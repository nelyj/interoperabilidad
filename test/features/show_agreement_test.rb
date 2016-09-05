require "test_helper"
require_relative 'support/agreement_creation_helper'

class ShowAgreementTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pedro), scope: :user
    create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit root_path
    find('#user-menu').click
    within '#user-menu' do
      find('#agreements').click
    end
  end

  test 'Download agreement PDF' do

    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      find(:xpath, 'li[2]').click
      assert_text find('li.active')[:text], 'Consumidor'
    end

    within '#consumidor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
      find(:xpath, '//table/tbody/tr[1]').click
    end

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    click_link "Descargar PDF"
  end

  test 'Next Step' do
    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      find(:xpath, 'li[2]').click
      assert_text find('li.active')[:text], 'Consumidor'
    end

    within '#consumidor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
      find(:xpath, '//table/tbody/tr[1]').click
    end

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content 'Próximo Paso Borrador enviado'
    assert_content 'Responsable: Contacto: '
  end

  test 'History' do
    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      find(:xpath, 'li[2]').click
      assert_text find('li.active')[:text], 'Consumidor'
    end

    within '#consumidor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
      find(:xpath, '//table/tbody/tr[1]').click
    end

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'

    assert_content 'Estado del convenio BORRADOR'

    find_button('Enviar Borrador').turboclick

    assert_content 'Estado del convenio EN PROGRESO'
    assert_content 'Historial del convenio'
    assert_content 'Borrador enviado'
    assert_content 'Borrador creado'
    assert_content 'Responsable: Pedro Pica Piedra Contacto: mail@example.org'
    has_button? 'Firmar Solicitud'
  end

  test 'Agreement state' do
    assert_content 'Convenios Servicio de Impuestos Internos'
    assert_link 'Crear Nuevo Convenio'
    within '.nav.nav-tabs' do
      find(:xpath, 'li[2]').click
      assert_text find('li.active')[:text], 'Consumidor'
    end

    within '#consumidor' do
      assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
      find(:xpath, '//table/tbody/tr[1]').click
    end

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content 'Estado del convenio BORRADOR'

    button = find_button('Enviar Borrador')
    button.turboclick

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content 'Estado del convenio EN PROGRESO'

  end

end
