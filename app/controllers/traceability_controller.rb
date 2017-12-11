class TraceabilityController < ApplicationController
  skip_before_action :verify_authenticity_token

  def endpoints_info
    # params => { secret: ENV['TRAZABILIDAD_SECRET'] }
    return head(401) if params[:secret] != ENV['TRAZABILIDAD_SECRET']
    render json: { services: Service.all.map(&method(:payload_for_service)) }
  end

  def payload_for_service(service)
    hsh = { url: service&.service_versions&.current&.first&.base_url }
    return hsh if service.public?
    hsh[:token] = service.generate_client_token
    hsh
  end
end