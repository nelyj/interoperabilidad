class MonitorParamsController < ApplicationController
  before_action :set_monitor_param, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :create, :edit]

  # GET /monitor_params
  # GET /monitor_params.json
  def index
    @monitor_params = MonitorParam.all
  end

  # GET /monitor_params/1
  # GET /monitor_params/1.json
  def show
  end

  # GET /monitor_params/new
  def new
    @monitor_param = MonitorParam.new
  end

  # GET /monitor_params/1/edit
  def edit
  end

  # POST /monitor_params
  # POST /monitor_params.json
  def create
    @monitor_param = MonitorParam.new(monitor_param_params)
    if @monitor_param.save
      redirect_to monitor_params_path, notice: t(:new_monitor_param_created)
    else
      render :new
    end
  end

  # PATCH/PUT /monitor_params/1
  # PATCH/PUT /monitor_params/1.json
  def update
    if @monitor_param.update(monitor_param_params)
      redirect_to monitor_params_path, notice: t(:monitor_param_updated)
    else
      render :edit
    end
  end

  # DELETE /monitor_params/1
  # DELETE /monitor_params/1.json
  def destroy
    @monitor_param.destroy
    redirect_to monitor_params_url, notice: t(:monitor_param_deleted)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_monitor_param
      @monitor_param = MonitorParam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def monitor_param_params
      params.require(:monitor_param).permit(:health_check_frequency, :unavailable_threshold, :organization_id)
    end

    def set_organizations
      @organizations = Organization.all
    end
end
