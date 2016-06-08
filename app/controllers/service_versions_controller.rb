class ServiceVersionsController < ApplicationController

  def show
    set_service
    @service_version = ServiceVersion.find(params[:version_number])
  end

  def index
    set_service
    @service_versions = @service.service_versions
  end

  def new
    set_service
    @service_version = ServiceVersion.new
  end

  def create
    set_service
    @service_version = @service.service_versions.build(service_version_params)
    if @service_version.save
      redirect_to [@service, @service_version], notice: 'service_version was successfully created.'
    else
      render :new
    end
  end

  private

  def service_version_params
    params.require(:service_version).permit(:spec_file)
  end

  def set_service
    @service = Service.find_by(name: params[:service_name])
  end
end
