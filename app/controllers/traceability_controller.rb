require 'signer'

class TraceabilityController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_token, only: :endpoints_info

  def endpoints_info
    render json: { services: Service.all.map(&method(:payload_for_service)) }
  end

  def get_token
    # params => {user: 'someusername', secret: 'ENV["TRAZABILIDAD_SECRET"]'
    return head(401) if params[:secret] != ENV['TRAZABILIDAD_SECRET']
    payload = { exp: (Time.now + 1.day).to_i, name: params[:user] }
    render json: { token: SignerApi.encode_token(payload,
                                                 ENV['TRAZABILIDAD_SECRET']) }
  end

  def payload_for_service(service)
    hsh = { url: service&.service_versions&.current&.first&.base_url }
    return hsh if service.public?
    hsh[:token] = service.generate_client_token
    return hsh unless hsh[:token].nil?
    service.generate_provider_credentials
    hsh[:token] = service.generate_client_token
    hsh
  end

  private
  def verify_token
    # params => { token: sometoken }
    return head(401) if params[:token].nil?
    JSON::JWT.decode(params[:token], ENV['TRAZABILIDAD_SECRET'])
  rescue JSON::JWS::VerificationFailed
    return head(401)
  end
end