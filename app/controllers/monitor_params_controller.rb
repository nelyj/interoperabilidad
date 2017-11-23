class MonitorParamsController < ApplicationController
  before_action :set_monitor_param, only: [:edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :create, :edit]

  def index
    @monitor_params = MonitorParam.all
  end

  def new
    @monitor_param = MonitorParam.new
  end

  def edit
  end

  def create
    @monitor_param = MonitorParam.new(monitor_param_params_new)
    if @monitor_param.save
      ServiceVersion.joins(:service).where(services: {organization_id: @monitor_param.organization_id}).current.each(&:reschedule_health_checks)
      redirect_to monitor_params_path, notice: t(:new_monitor_param_created)
    else
      render :new
    end
  end

  def update
    if @monitor_param.update(monitor_param_params)
      ServiceVersion.joins(:service).where(services: {organization_id: @monitor_param.organization_id}).current.each(&:reschedule_health_checks)
      redirect_to monitor_params_path, notice: t(:monitor_param_updated)
    else
      render :edit
    end
  end

  def destroy
    @monitor_param.destroy
    ServiceVersion.joins(:service).where(services: {organization_id: @monitor_param.organization_id}).current.each(&:reschedule_health_checks)
    redirect_to monitor_params_url, notice: t(:monitor_param_deleted)
  end

  private

    def set_monitor_param
      @monitor_param = MonitorParam.find(params[:id])
    end

    def monitor_param_params_new
      params.require(:monitor_param).permit(:health_check_frequency, :unavailable_threshold, :organization_id)
    end

    def monitor_param_params
      params.require(:monitor_param).permit(:health_check_frequency, :unavailable_threshold)
    end

    def set_organizations
      @organizations = Organization.all
    end
end
