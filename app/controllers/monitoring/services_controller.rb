class Monitoring::ServicesController < ApplicationController
  before_action :check_service_admin, except: [:index, :show]

  def index
    organization
  end

  def show
    service
  end

  def disable
    service.update_attribute(:monitoring_enabled, false)
    service.current_version&.stop_health_checks
    redirect_to monitoring_organization_services_path(organization)
  end

  def enable
    service.update_attribute(:monitoring_enabled, true)
    service.current_version&.schedule_health_checks
    redirect_to monitoring_organization_services_path(organization)
  end

  private

  def organization
    @organization ||= Organization.where(name: params[:organization_name]).first
  end

  def service
    @service ||= organization.services.where(name: params[:name]).first
  end

  def check_service_admin
    unless current_user&.is_service_admin?
      redirect_to monitoring_organization_services_path(organization)
    end
  end

end
