class ServicesController < ApplicationController
  before_action :set_organization, only: [:index, :new, :create, :show, :client_token]
  before_action :set_service, only: [:edit, :update, :show, :client_token]

  def index
    if user_signed_in? && @organization.is_member?(current_user)
      @services = @organization.services.all
    else
      redirect_to services_path, notice: t(:not_enough_permissions)
    end
  end

  def show
    if user_signed_in? && (current_user.is_service_admin? || current_user == @service.last_version.user)
      # For people on the service approval workflow, it's best to see the last version
      target_version = @service.last_version
    else
      # Other people would likely prefer to see the last approved version (if it exists)
      target_version = @service.current_or_last_version
    end
    redirect_to organization_service_service_version_path(@organization, @service, target_version)
  end

  def new
    return unless user_signed_in?
    if @organization.can_create_service_or_version?(current_user)
       @service = Service.new
    else
      redirect_to organization_services_path(@organization), notice: t(:not_enough_permissions)
    end
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      @service.create_first_version(current_user)
      redirect_to(
        [@organization, @service, @service.service_versions.first],
        notice: t(:new_service_created)
      )
    else
      flash.now[:error] = t(:cant_create_service)
      render action: "new"
    end
  end

  def edit
    if user_signed_in? && @service.can_be_updated_by?(current_user)
      current_user.organizations.where(id: @service.organization.id).length > 0
    else
      redirect_to organization_services_path(@organizaton), notice: t(:not_enough_permissions)
    end
  end

  def update
    if @service.update(params.require(:service).permit(:organization_id))
      redirect_to organization_services_path(@organization), notice: t(:service_updated)
    else
      render :edit
    end
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
    agreement = @service.agreements.where(id: client_id.to_i).first
    if agreement.nil? || agreement.client_secret != client_secret
      render status: 400, json: {
        error: 'invalid_client',
        error_description: 'Invalid Client ID or Client Secret'
      }
      return
    end
    render json: {
      access_token: agreement.generate_client_token(@service),
      token_type: 'bearer',
      expires_in: agreement.client_token_expiration_in_seconds,
    }
  end



  private
    def service_params
      params.require(:service).permit(:organization_id, :name, :spec_file, :public, :backwards_compatible, :custom_mock_service)
    end
    def set_service
      @service = @organization.services.where(name: params[:service_name] || params[:name]).first
    end
    def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
    end
end
