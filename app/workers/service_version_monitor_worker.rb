class ServiceVersionMonitorWorker
  include Sidekiq::Worker

  def perform(service_version_id)
    service_version = ServiceVersion.find(service_version_id)
    if service_version.current?
      service_version.perform_health_check!
    else
      Rails.logger.warn("ServiceVersionMonitorWorker: Service version #{service_version_id} not current and shouldn't be monitored")
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("ServiceVersionMonitorWorker: Service version #{service_version_id} not found")
    return
  end
end
