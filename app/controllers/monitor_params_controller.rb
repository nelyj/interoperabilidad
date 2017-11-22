class MonitorParamsController < ApplicationController
  before_action :set_monitor_param, only: [:show, :edit, :update, :destroy]

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

    respond_to do |format|
      if @monitor_param.save
        format.html { redirect_to @monitor_param, notice: 'Monitor param was successfully created.' }
        format.json { render :show, status: :created, location: @monitor_param }
      else
        format.html { render :new }
        format.json { render json: @monitor_param.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /monitor_params/1
  # PATCH/PUT /monitor_params/1.json
  def update
    respond_to do |format|
      if @monitor_param.update(monitor_param_params)
        format.html { redirect_to @monitor_param, notice: 'Monitor param was successfully updated.' }
        format.json { render :show, status: :ok, location: @monitor_param }
      else
        format.html { render :edit }
        format.json { render json: @monitor_param.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /monitor_params/1
  # DELETE /monitor_params/1.json
  def destroy
    @monitor_param.destroy
    respond_to do |format|
      format.html { redirect_to monitor_params_url, notice: 'Monitor param was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_monitor_param
      @monitor_param = MonitorParam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def monitor_param_params
      params.require(:monitor_param).permit(:min, :hour, :dayOfMonth, :month, :dayOfWeek, :unavailable_threshold, :belongs_to)
    end
end
