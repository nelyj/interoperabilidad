class Monitoring::OrganizationsController < ApplicationController
  def index
    @organizations = Organization.with_services
  end

  def show

  end
end
