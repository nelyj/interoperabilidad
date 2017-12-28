module AgreementCreationHelper

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
      name: 'test-service'+SecureRandom.uuid,
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:pedro))
    service
  end

  def create_valid_schema!
    schema = Schema.create!(
      name: 'test-schema'+SecureRandom.uuid,
      spec_file: StringIO.new(VALID_SCHEMA_OBJECT),
      schema_categories: [schema_categories(:informacion_de_personas)]
    )
    schema.create_first_version(users(:pedro))
    schema
  end

  def create_valid_agreement!(orgp, orgc)
    service = create_valid_service!
    agreement = Agreement.create!(
      service_provider_organization: orgp,
      service_consumer_organization: orgc,
      user: users(:pedro),
      purpose: "test only",
      services: [service])
    generate_pdf(agreement, agreement.agreement_revisions.first)
    agreement
  end

end
