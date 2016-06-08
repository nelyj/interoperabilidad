class ServicesController < ApplicationController

  def index
    @services = Service.all
    set_organizations
  end

  def new
    @service = Service.new
    set_organizations
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to [@service, @service.service_versions.first], notice: 'service was successfully created.'
    else
      flash.now[:error] = "Could not save service"
      render action: "new"
    end
  end

  def edit
    set_service
    set_organizations
  end

  def update
    set_service
    if @service.update(params.require(:service).permit(:organization_id))
      redirect_to services_path, notice: 'service was successfully updated.'
    else
      render :edit
    end
  end

  private
    def service_params
      params.require(:service).permit(:organization_id, :name, :spec_file)
    end
    def set_service
      @service = Service.find_by(name: params[:name])
    end

    def set_organizations
      @organizations = Organization.all
    end
end