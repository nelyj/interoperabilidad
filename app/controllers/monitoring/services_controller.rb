class Monitoring::ServicesController < ApplicationController
  def index
    @organization = Organization.where(name: params[:organization_name]).first
  end

end
