class Monitoring::ServicesController < ApplicationController
  def index
    @organization = Organization.where(name: params[:organization_name]).first
  end

  def show
    @organization = Organization.where(name: params[:organization_name]).first
    @service = @organization.services.where(name: params[:name]).first
  end
end
