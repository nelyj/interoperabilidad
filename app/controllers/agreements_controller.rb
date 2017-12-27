class AgreementsController < ApplicationController
  include PdfGenerator
  before_action :set_organization
  before_action :set_provider_orgs, only:[:create, :new]

  def index
    return unless user_signed_in?
    if @organization.is_member?(current_user)
      @provided_agreements = Agreement.where(service_provider_organization: @organization)
      @consumed_agreements = Agreement.where(service_consumer_organization: @organization)
    else
      redirect_to services_path, notice: t(:not_enough_permissions)
    end
  end

  def new
    return unless user_signed_in?
    if @organization.is_member?(current_user) && current_user.can_create_agreements?(@organization)
      @agreement = Agreement.new
    else
      redirect_to services_path, notice: t(:not_enough_permissions)
    end
  end

  def create
    @agreement = Agreement.new(agreement_params.merge(user: current_user))
    if @agreement.save
      generate_pdf(@agreement, @agreement.last_revision)
      @agreement.last_revision.send_notifications
      redirect_to(
        organization_agreement_agreement_revision_path(@organization, @agreement,  @agreement.agreement_revisions.last.revision_number),
        notice: t(:new_agreement_created)
      )
    else
      flash.now[:error] = t(:cant_create_agreement)
      render action: "new"
    end
  end

  # this method is the first stop when some flow action of the agreement is triggered
  # based on the 'next_step' parameter and the current state of the agreement.
  # Considering that the next_step parameter (a state of the agreement) is the action that needs to occur,
  # this method call the associated flow action method on the agreement model,
  # this means that if the next step of the agreement is for example 'validated_draft'
  # the action called should be 'validate_draft'.
  # If for one action there are more than one possible interaction (for example: signed_draft -> sign_draft and object_draft)
  # the triggered action is determined by the submit button pressed on the view, which is included in the
  # params under the name of the clicked button
  def flow_actions_router
    @agreement = Agreement.find(params[:agreement_id])
    step_for_message = params[:next_step]
    case params[:next_step]
    when "validated_draft"
      if params.include?(t(:send_draft))
        @agreement_revision = @agreement.validate_draft(current_user)
      else
        return redirect_to new_organization_agreement_agreement_revision_path
      end
    when "signed_draft"
      if params.include?(t(:sign_request))
        @agreement_revision = @agreement.sign_draft(current_user, params[:one_time_password])
      else
        @agreement_revision = @agreement.object_draft(current_user, agreement_params[:objection_message])
      end
    when "draft"
      return redirect_to new_organization_agreement_agreement_revision_path
    when "validated"
      if params.include?(t(:request_signature))
        @agreement_revision = @agreement.validate_revision(current_user)
      else
        @agreement_revision = @agreement.object_draft(current_user, agreement_params[:objection_message])
        step_for_message = 'draft'
      end
    when "reject_signature"
      @agreement_revision = @agreement.validate_revision(current_user)
    when "signed"
      if params.include?(t(:sign_request))
        @agreement_revision = @agreement.sign(current_user, params[:one_time_password])
      else
        @agreement_revision = @agreement.reject_sign(current_user, agreement_params[:objection_message])
        step_for_message = 'reject_signature'
      end
    end
    if @agreement_revision.nil?
      redirect_to [@organization, @agreement, @agreement.last_revision], notice: messages_for(step_for_message, :error_message)
    else
      @agreement_revision.send_notifications
      redirect_to [@organization, @agreement, @agreement_revision], notice: messages_for(step_for_message, :success_message)
    end
  end

  def global
    return unless user_signed_in?
    if current_user.is_service_admin?
      @agreements = Agreement.all
    else
      redirect_to root_path, notice: t(:not_enough_permissions)
    end
  end

  def new_injection
    return unless user_signed_in?
    if current_user.is_service_admin?
      @agreement = Agreement.new
    else
      redirect_to root_path, notice: t(:not_enough_permissions)
    end
  end

  def inject
    return unless user_signed_in?
    redirect_to root_path, notice: t(:not_enough_permissions) unless current_user.is_service_admin?

    @agreement = Agreement.new(injection_params.merge(user: current_user))
    file = params.require('/agreements/global').permit(:file)[:file]

    if file&.content_type == 'application/pdf' && @agreement.save
      @agreement.new_revision(current_user,:signed,I18n.t(:signed_log),'', file)
      inject_pdf(@agreement, @agreement.last_revision, file)
      @agreement.last_revision.send_notifications
      redirect_to(agreements_global_path , notice: t(:new_agreement_created))
    else
      @agreement.delete
      @agreement.errors.add(:base, t(:file_must_be_pdf)) if file.nil? || file.content_type != 'application/pdf'
      flash.now[:error] = t(:cant_create_agreement)
      render action: "new_injection"
    end
  end

private

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
      :service_consumer_organization_id, :purpose, :legal_base,
      :objection_message, :one_time_password, :next_step, :service_ids => [])
  end

  def injection_params
    params.require('/agreements/global').permit(:service_provider_organization_id,
      :service_consumer_organization_id, :purpose, :legal_base,
      :objection_message, :one_time_password, :next_step, :service_ids => [])
  end

  def set_organization
    @organization = Organization.where(name: params[:organization_name]).first
  end

  def set_provider_orgs
    @provider_organizations = Organization.where.not(id: @organization)
  end

  def messages_for(state, type)
    {
      "validated_draft" => {
        error_message: t(:agreement_wrongly_sent),
        success_message: t(:agreement_correctly_sent)
      },
      "signed_draft" => {
        error_message: t(:agreement_wrongly_signed),
        success_message: t(:agreement_correctly_signed)
      },
      "draft" => {
        error_message: t(:objection_wrongly_sent),
        success_message: t(:objection_correctly_sent)
      },
      "validated" => {
        error_message: t(:agreement_wrongly_sent),
        success_message: t(:agreement_correctly_sent)
      },
      "signed" => {
        error_message: t(:agreement_wrongly_signed),
        success_message: t(:agreement_correctly_signed)
      },
      "reject_signature" => {
        error_message: t(:rejection_wrongly_sent),
        success_message: t(:rejection_correctly_sent)
      }
    }[state][type] || {}
  end
end
