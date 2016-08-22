class AgreementRevisionsController < ApplicationController
  include PdfGenerator
  before_action :set_agreement

  def show
    @agreement_revision = @agreement.agreement_revisions.where(revision_number: params[:revision_number]).first
    @provider_organization = Organization.find(@agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(@agreement.service_consumer_organization_id)
  end

  def new
    @agreement_revision = @agreement.agreement_revisions.new
    @last_revision = @agreement.last_revision
    @organization = Organization.find_by_name(params[:organization_name])
    @provider_organization = Organization.find(@agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(@agreement.service_consumer_organization_id)
  end

  def create
    @organization = Organization.find_by_name(params[:organization_name])
    @agreement_revision = @agreement.agreement_revisions.build(agreement_revision_params)
    @agreement_revision.user = current_user
    @agreement_revision.log = "Nuevo paso"
    if @agreement_revision.save!
      generate_pdf(@agreement, @agreement_revision)
      redirect_to [@organization, @agreement, @agreement_revision], notice: 'Convenio modificado correctamente'
    else
      render :new
    end
  end

  def request_validation
    @organization = Organization.find_by_name(params[:organization_name])
    @agreement_revision = @agreement.validate_draft(current_user)
    generate_pdf(@agreement, @agreement_revision)
    redirect_to [@organization, @agreement, @agreement_revision], notice: 'Convenio enviado correctamente'
  end

private

  def agreement_revision_params
    params.require(:agreement_revision).permit(:purpose, :legal_base)
  end

  def set_agreement
    @agreement = Agreement.find(params[:agreement_id])
  end
end
