class AgreementsController < ApplicationController
  before_action :set_organization

  def index
    @agreements = Agreement.all
  end

  def show
  end

  def new
    @agreement = Agreement.new
  end

  def create
    @agreement = Agreement.new(agreement_params)
    if @agreement.save
      redirect_to(agreements_path)
    else
      flash.now[:error] = t(:cant_create_service)
      render action: "new"
    end
  end

  def edit
  end

private

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
      :service_consumer_organization_id)
  end

  def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
  end
end
