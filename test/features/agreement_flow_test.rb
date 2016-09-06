require "test_helper"
require_relative 'support/agreement_creation_helper'

class AgreementFlowTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def visit_created_agreement(user, side)
    login_as user, scope: :user
    visit root_path
    find('#user-menu').click
    within '#user-menu' do
      find('#agreements').click
    end

    if (side.include?('Consumidor'))
      assert_link 'Crear Nuevo Convenio'
      within '.nav.nav-tabs' do
        find(:xpath, 'li[2]').click
        assert_text find('li.active')[:text], 'Consumidor'
      end

      within '#consumidor' do
        assert find(:xpath, '//table/thead/tr').text.include?('Institución proveedora Servicios involucrados Propósito Fecha ult. movimiento Estado')
        find(:xpath, '//table/tbody/tr[1]').click
      end
    else
      within '.nav.nav-tabs' do
        assert_text find('li.active')[:text], side
      end
      within '#proveedor' do
        assert find(:xpath, '//table/thead/tr').text.include?('Institución solicitante Servicios involucrados Propósito Fecha ult. movimiento Estado')
        find(:xpath, '//table/tbody/tr[1]').click
      end
    end
  end

  test 'object draft' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit_created_agreement(users(:pedro), 'Consumidor')
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    find_button('Enviar Borrador').turboclick
    assert agreement.last_revision.state.include?("validated_draft")
    assert_content 'Convenio enviado correctamente'
    find('.btn-danger').trigger('click')
    fill_in 'agreement_objection_message', :with => 'objection message for testing'
    find_button('Rechazar').turboclick
    assert agreement.last_revision.state.include?("objected")
    assert_content 'Borrador objetado'
    assert_content 'objection message for testing'
  end

  test 'displayed content of an Agreement' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit_created_agreement(users(:pedro), 'Consumidor')
    # participants
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content 'Solicitante: Servicio de Impuestos Internos'
    assert_content 'Proveedor: Secretaría General de la Presidencia'
    # request date
    assert_content "Fecha de solicitud: #{agreement.created_at.strftime("%d/%m/%Y")}"
    # involved services
    agreement.services.each do |service|
      assert_content "#{service.name}"
    end
    # purpose
    assert_content 'Propósito: test only'
    # agreement current state
    assert_content 'BORRADOR'
    # next step
    assert_content 'Borrador enviado'
    # history
    assert_content 'Borrador creado'
  end

  test 'Validate Draft' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit_created_agreement(users(:pedro), 'Consumidor')
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    button = find_button('Enviar Borrador')
    button.turboclick
    assert agreement.last_revision.state.include?("validated_draft")
  end

  test 'Validate Revision' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    user = users(:pablito)
    #This is necesary, because we can call signer on test (no way to input OTP)
    agreement.new_revision(user,"signed_draft","Manually Sign Draft","", "file")
    assert agreement.state.include?("signed_draft")

    visit_created_agreement(user, 'Proveedor')
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    button = find_button('Solicitar Firma')
    button.turboclick
    assert agreement.last_revision.state.include?("validated")
  end

  test 'Edit Agreement and save' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit_created_agreement(users(:pedro), 'Consumidor')
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    button = find_button('Editar')
    button.turboclick

    fill_in "agreement_revision_purpose", with: "Nuevo Propósito"
    button = find_button('Guardar')
    button.turboclick

    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content "Propósito: Nuevo Propósito"

  end

  test 'Edit Agreement and cancel' do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit_created_agreement(users(:pedro), 'Consumidor')
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    button = find_button('Editar')
    button.turboclick

    fill_in "agreement_revision_purpose", with: "Nuevo Propósito"

    within '.actions' do
      click_turbolink('Cancelar')
    end
    assert_content 'Convenio entre Servicio de Impuestos Internos y Secretaría General de la Presidencia'
    assert_content "Propósito: test only"

  end

end
