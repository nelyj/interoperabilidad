class Monitoring::OrganizationsController < ApplicationController
  def index
    @organizations = Organization.with_services.sort_by do |organization|
      -organization.services.unavailable.count
    end
  end
end
