class AgreementsController < ApplicationController
  include PdfGenerator
  before_action :set_organization

  def index
    @provided_agreements = Agreement.where(service_provider_organization: @organization)
    @consumed_agreements = Agreement.where(service_consumer_organization: @organization)
  end

  def show
  end

  def new
    @provider_organizations = Organization.where.not(id: @organization)
    @agreement = Agreement.new
  end

  def create
    @agreement = Agreement.new(agreement_params.merge(user: current_user))
    if @agreement.save!
      generate_pdf(@agreement, @agreement.agreement_revisions.first)
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

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
      :service_consumer_organization_id, :purpose, :legal_base, :service_ids => [])
  end

  def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
  end
end
