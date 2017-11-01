class ServiceVersionHealthCheck < ApplicationRecord
  belongs_to :service_version

  def healty?
    http_status == 200 && status_code == 200
  end
end
