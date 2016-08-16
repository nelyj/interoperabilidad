module PdfGenerator
  extend ActiveSupport::Concern

  def generate_pdf(agreement, agreement_revision)
    @agreement_revision = agreement_revision
    @provider_organization = Organization.find(agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(agreement.service_consumer_organization_id)
    file_name = "CID-#{agreement.id}-#{@agreement_revision.revision_number}_#{@provider_organization.initials.upcase}_#{@consumer_organization.initials.upcase}.pdf"
    file_path = Rails.root.join('tmp', file_name)
    render  :pdf => 'convenio',
            :template => 'agreement_revisions/template.html.haml',
            :assigns => { agreement: agreement, agreement_revision: agreement_revision },
            :save_to_file => file_path,
            :save_only => true
    @agreement_revision.upload_pdf(file_name, file_path)
    @agreement_revision.save
  end
end