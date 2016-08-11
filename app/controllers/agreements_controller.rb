class AgreementsController < ApplicationController
  before_action :set_organization

  def index
    @provided_agreements = Agreement.where(service_provider_organization: @organization)
    @consumed_agreements = Agreement.where(service_consumer_organization: @organization)
  end

  def show
  end

  def new
    @agreement = Agreement.new
  end

  def create
    @agreement = Agreement.new(agreement_params.merge(user: current_user))
    if @agreement.save!
      generate_pdf(@agreement)
      redirect_to(
        organization_agreement_agreement_revision_path(@organization, @agreement,  @agreement.agreement_revisions.last.revision_number),
        notice: t(:new_agreement_created)
      )
    else
      flash.now[:error] = t(:cant_create_agreement)
      render action: "new"
    end
  end

  def edit
  end

private

  def generate_pdf(agreement)
    @agreement_revision = agreement.agreement_revisions.first
    @provider_organization = Organization.find(agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(agreement.service_consumer_organization_id)
    file_name = "CID-#{agreement.id}-#{@agreement_revision.revision_number}_#{@provider_organization.initials.upcase}_#{@consumer_organization.initials.upcase}.pdf"
    file_path = Rails.root.join('tmp', file_name)
    render  :pdf => 'convenio',
            :template => 'agreement_revisions/template.html.haml',
            :assigns => { agreement: agreement },
            :save_to_file => file_path,
            :save_only => true
    @agreement_revision.upload_pdf(file_name, file_path)
    @agreement_revision.save
  end

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
      :service_consumer_organization_id, :purpose, :legal_base, :service_ids => [])
  end

  def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
  end
end
