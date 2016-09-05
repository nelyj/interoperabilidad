require "test_helper"

class AgreementFlowTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def generate_pdf(agreement, agreement_revision)
    provider_organization = Organization.find(agreement.service_provider_organization_id)
    consumer_organization = Organization.find(agreement.service_consumer_organization_id)
    file_name = "TEST-CID-#{agreement.id}-#{agreement_revision.revision_number}_#{provider_organization.initials.upcase}_#{consumer_organization.initials.upcase}.pdf"
    file_path = Rails.root.join('test/files/test-agreement/', file_name)
    File.open(file_path, 'wb') {|f| f.write("Hello World")}
    agreement_revision.upload_pdf(file_name, file_path)
  end

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
      purpose: 'test only',
      services: [service])
    generate_pdf(agreement, agreement.agreement_revisions.first)
    agreement
  end

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

end
