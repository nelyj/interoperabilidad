class ServiceVersionsController < ApplicationController
  before_action :set_service

  def show
    @service_version = ServiceVersion.find_by(version_number: params[:version_number])
  end

  def index
    @service_versions = @service.service_versions
  end

  def new
    if user_signed_in? && @service.can_be_updated_by?(current_uesr)
       @service_version = ServiceVersion.new
    else
      redirect_to service_service_versions_path(@service), notice: 'no tiene permisos suficientes'
    end
  end

  def create
    @service_version = @service.service_versions.build(service_version_params)
    @service_version.user = current_user
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
