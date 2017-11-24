class MonitorParam < ApplicationRecord
  belongs_to :organization
  validates :organization, uniqueness: true
  after_save :reschedule_monitoring_for_all_organization_services
  after_destroy :reschedule_monitoring_for_all_organization_services

  def reschedule_monitoring_for_all_organization_services
    ServiceVersion.current.joins(:services).where(
      services: {organization_id: organization_id})
    ).each(&:reschedule_health_checks)
  end

end
