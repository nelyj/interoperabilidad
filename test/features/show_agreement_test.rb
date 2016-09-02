require "test_helper"

class ShowAgreementTest < Capybara::Rails::TestCase
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
      services: [service])
    generate_pdf(agreement, agreement.agreement_revisions.first)
    agreement
  end

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
