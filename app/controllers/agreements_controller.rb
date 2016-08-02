class AgreementsController < ApplicationController
  before_action :set_organization

  def index
    
  end

  def show
  end

  def new
  end

  def edit
  end

  private
    def service_params
      params.require(:service).permit(:organization_id, :name, :spec_file, :public, :backwards_compatible)
    end

    def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
    end
end
