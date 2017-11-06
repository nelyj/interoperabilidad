class ServiceVersionMonitorWorker
  include Sidekiq::Worker

  def perform(service_version_id)
    service_version = ServiceVersion.find(service_version_id)
    unless service_version
      Rails.logger.warn("ServiceVersionMonitorWorker: Service version #{service_version_id} not found")
      return
    end
    unless service_version.current?
      Rails.logger.warn("ServiceVersionMonitorWorker: Service version #{service_version_id} not current and shouldn't be monitored")
      return
    end
    service_version.perform_health_check!
  end
end
