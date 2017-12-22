module PdfGenerator
  extend ActiveSupport::Concern

  def generate_pdf(agreement, agreement_revision)
    @agreement_revision = agreement_revision

    file_name = "CID-#{agreement.id}-#{@agreement_revision.revision_number}_#{agreement.service_provider_organization.initials.upcase}_#{agreement.service_consumer_organization.initials.upcase}.pdf"
    file_path = Rails.root.join('tmp', file_name)
    render  :pdf => 'convenio',
            :template => 'agreement_revisions/template.html.haml',
            :assigns => { agreement: agreement, agreement_revision: agreement_revision },
            :save_to_file => file_path,
            :save_only => true
    @agreement_revision.upload_pdf(file_name, file_path)
  end
end
