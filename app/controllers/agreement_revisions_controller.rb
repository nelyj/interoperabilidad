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
      #TODO: notify here
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_revision_edited)
    else
      render :new
    end
  end

  def validation_request
    @agreement_revision = @agreement.validate_draft(current_user)
    if @agreement_revision.nil?
      flash.now[:error] = t(:agreement_wrongly_sent)
    else
      #TODO: notify here
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_correctly_sent)
    end
  end

  def consumer_signature
    @agreement_revision = @agreement.sign_draft(current_user, 0)
    if @agreement_revision.nil?
      redirect_to [@organization, @agreement, @agreement.last_revision], notice: t(:agreement_wrongly_signed)
    else
      #TODO: notify here
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_correctly_signed)
    end
  end

  def objection_request
    @agreement_revision = @agreement.object_draft(current_user, agreement_revision_params[:objection_message])
    if @agreement_revision.nil?
      flash.now[:error] = t(:objection_wrongly_sent)
    else
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:objection_correctly_sent)
    end
  end

  def document_validation
    @agreement_revision = @agreement.validate_revision(current_user)
    if @agreement_revision.nil?
      flash.now[:error] = t(:agreement_wrongly_sent)
    else
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_correctly_sent)
    end
  end

  def provider_signature
    @agreement_revision = @agreement.sign(current_user, 0)
    if @agreement_revision.nil?
      redirect_to [@organization, @agreement, @agreement.last_revision], notice: t(:agreement_wrongly_signed)
    else
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:agreement_correctly_signed)
    end
  end

  def reject_signature
    @agreement_revision = @agreement.reject_sign(current_user, agreement_revision_params[:objection_message])
    if @agreement_revision.nil?
      flash.now[:error] = t(:rejection_wrongly_sent)
    else
      redirect_to [@organization, @agreement, @agreement_revision], notice: t(:rejection_correctly_sent)
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
