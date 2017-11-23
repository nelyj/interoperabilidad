class MonitorParam < ApplicationRecord
  belongs_to :organization
  validates :organization, uniqueness: true
  after_save :callReschedule
  after_destroy :callReschedule

  def callReschedule
    ServiceVersion.joins(:service).where(services: {organization_id: organization_id}).current.each(&:reschedule_health_checks)
  end

end
