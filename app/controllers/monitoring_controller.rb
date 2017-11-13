class MonitoringController < ApplicationController
  def show
    @organizations = Organization.with_services
  end
end
