class ServicesController < ApplicationController
  before_action :set_service, only: [:edit, :update]

  def index
    @pending_services_version = ServiceVersion.proposed
    if params[:search]
      @services = Service.search(params[:search])
    else
      @services = Service.all
    end
  end

  def new
   if user_signed_in? &&
    current_user.roles.where(name: "Service Provider").length >= 1
       @service = Service.new
    else
      redirect_to services_path, notice: 'no tiene permisos suficientes'
    end
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      @service.create_first_version(current_user)
      redirect_to [@service, @service.service_versions.first], notice: 'Servicio creado correctamente'
    else
      flash.now[:error] = "No se pudo crear el servicio"
      render action: "new"
    end
  end

  def edit
    if user_signed_in? &&
      current_user.organizations.where(id: @service.organization.id).length > 0
    else
      redirect_to services_path, notice: 'no tiene permisos suficientes'
    end
  end

  def update
    if @service.update(params.require(:service).permit(:organization_id))
      redirect_to services_path, notice: 'Servicio actualizado correctamente'
    else
      render :edit
    end
  end

  private
    def service_params
      params.require(:service).permit(:organization_id, :name, :spec_file, :public, :backwards_compatible)
    end
    def set_service
      @service = Service.where(name: params[:name]).take
    end
end
