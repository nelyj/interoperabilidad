class ServiceVersionHealthCheck < ApplicationRecord
  belongs_to :service_version
  default_scope { order(created_at: :asc) }
  before_create :set_healthy_flag
  after_create :update_service_version_availability_status

  def set_healthy_flag
    self.healthy = (http_status == 200 && status_code == 200)
  end

  def update_service_version_availability_status
    service_version.update_availability_status
  end
end
