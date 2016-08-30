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

  def validation_request
    flow_actions(t(:agreement_wrongly_sent), t(:agreement_correctly_sent))
  end

  def consumer_signature
    flow_actions(t(:agreement_wrongly_signed), t(:agreement_correctly_signed))
  end

  def objection_request
    flow_actions(t(:objection_wrongly_sent), t(:objection_correctly_sent))
  end

  def document_validation
    flow_actions(t(:agreement_wrongly_sent), t(:agreement_correctly_sent), false)
  end

  def provider_signature
    flow_actions(t(:agreement_wrongly_signed), t(:agreement_correctly_signed), false)
  end

  def reject_signature
    flow_actions(t(:rejection_wrongly_sent), t(:rejection_correctly_sent))
  end

private

  def agreement_revision_params
    params.require(:agreement_revision).permit(:purpose, :legal_base, :objection_message, :one_time_password)
  end

  def set_agreement
    @agreement = Agreement.find(params[:agreement_id])
  end

  def set_organization
    @organization = Organization.find_by_name(params[:organization_name])
  end

  def flow_actions(error_message, success_message, needs_new_pdf = true)
    case params[:action]
    when "validation_request"
      @agreement_revision = @agreement.validate_draft(current_user)
    when "consumer_signature"
      @agreement_revision = @agreement.sign_draft(current_user)
    when "objection_request"
      @agreement_revision = @agreement.object_draft(current_user, agreement_revision_params[:objection_message])
    when "document_validation"
      @agreement_revision = @agreement.validate_revision(current_user)
    when "provider_signature"
      @agreement_revision = @agreement.sign(current_user)
    when "reject_signature"
      @agreement_revision = @agreement.reject_sign(current_user, agreement_revision_params[:objection_message])
    end
    if @agreement_revision.nil?
      render :show
      flash.now[:error] = error_message
    else
      generate_pdf(@agreement, @agreement_revision) if needs_new_pdf
      redirect_to [@organization, @agreement, @agreement_revision], notice: success_message
    end
  end
end
