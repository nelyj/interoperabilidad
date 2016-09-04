class AgreementRevisionsController < ApplicationController
  include PdfGenerator
  before_action :set_agreement
  before_action :set_organization

  def show
    @agreement_revision = @agreement.agreement_revisions.where(revision_number: params[:revision_number]).first
    if @agreement_revision.nil? || @agreement.last_revision_number != params[:revision_number].to_i
      redirect_to [@organization, @agreement, @agreement.last_revision]
    else
      @provider_organization = Organization.find(@agreement.service_provider_organization_id)
      @consumer_organization = Organization.find(@agreement.service_consumer_organization_id)
    end
  end

  def new
    @agreement_revision = AgreementRevision.new
    @last_revision = @agreement.last_revision
    @provider_organization = Organization.find(@agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(@agreement.service_consumer_organization_id)
  end

  def create
    @agreement_revision = @agreement.agreement_revisions.build(agreement_revision_params)
    @agreement_revision.user = current_user
    @agreement_revision.log = t(:modified_draft_log)
    if @agreement_revision.save!
      generate_pdf(@agreement, @agreement_revision)
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_revision_edited)
    else
      render :new
    end
  end

private

  def agreement_revision_params
    params.require(:agreement_revision).permit(:purpose, :legal_base)
  end

  def set_agreement
    @agreement = Agreement.find(params[:agreement_id])
  end

  def set_organization
    @organization = Organization.find_by_name(params[:organization_name])
  end

end
