class ServicesController < ApplicationController
  before_action :set_organization, only: [:index, :new, :create]
  before_action :set_service, only: [:edit, :update]

  def index
    @services = Service.all
  end

  def search
    @text_search = params[:text_search]
    @services = Service.search(params[:text_search])
  end

  def pending_approval
    @pending_services_version = ServiceVersion.proposed
  end

  def new
    if user_signed_in? && current_user.roles.exists?(name: "Service Provider")
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
      flash.now[:error] = test(:cant_create_service)
      render action: "new"
    end
  end

  def edit
    if user_signed_in? &&
      current_user.organizations.where(id: @service.organization.id).length > 0
    else
      redirect_to organization_services_path(@organizaton), notice: :not_enough_permissions
    end
  end

  def update
    if @service.update(params.require(:service).permit(:organization_id))
      redirect_to organization_services_path(@organization), notice: t(:service_updated)
    else
      render :edit
    end
  end

  private
    def service_params
      params.require(:service).permit(:organization_id, :name, :spec_file, :public, :backwards_compatible)
    end
    def set_service
      @service = @organization.services.where(name: params[:service_name]).first
    end
    def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
    end
end
