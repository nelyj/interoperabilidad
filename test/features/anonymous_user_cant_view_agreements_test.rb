require "test_helper"

class AnonymousUserCantViewAgreementsTest < Capybara::Rails::TestCase
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

  test "anonymous user can't view agreements list" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit organization_agreements_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Convenios Subsecretaría General de La Presidencia")
    assert page.has_content?("Para revisar convenios por favor identifíquese con su clave única")
  end

  test "anonymous user can't create new agreement" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Crear Nuevo Convenio Subsecretaría General de La Presidencia")
    assert page.has_content?("Para crear convenios por favor identifíquese con su clave única")
  end

  test "anonymous user can't create new agreement revision" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_agreement_revision_path(agreement.service_consumer_organization, agreement)
    assert page.has_no_content?("Nueva Versión")
    assert page.has_content?("Para crear convenios por favor identifíquese con su clave única")
  end
end
