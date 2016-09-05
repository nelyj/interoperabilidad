class AgreementsController < ApplicationController
  include PdfGenerator
  before_action :set_organization
  before_action :set_provider_orgs, only:[:create, :new]

  def index
    @provided_agreements = Agreement.where(service_provider_organization: @organization)
    @consumed_agreements = Agreement.where(service_consumer_organization: @organization)
  end

  def new
    @agreement = Agreement.new
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
      @agreement_revision = @agreement.validate_revision(current_user)
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

private

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
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

  def client_token
    if params[:grant_type] != 'client_credentials'
      render status: 400, json: {error: 'unsupported_grant_type'}
      return
    end
    match = /^Basic (.*)/.match(request.authorization)
    if match
      decoded = Base64.decode64(match[1])
      client_id, client_secret = decoded.split(':')
    else
      client_id = params[:client_id]
      client_secret = params[:client_secret]
    end
    if client_id.nil? || client_secret.nil?
      render status: 400, json: {
        error: 'invalid_client',
        error_description: 'Client ID or Client Secret is missing'
      }
      return
    end
    agreement = Agreement.find(client_id.to_i)
    if ageement.client_secret != client_secret
      render status: 400, json: {
        error: 'invalid_client',
        error_description: 'Invalid Client ID or Client Secret'
      }
    end
    render json: {
      access_token: agreement.generate_client_token,
      token_type: 'bearer',
      expires_in: agreement.client_token_expiration_in_seconds,
    }
  end

end
