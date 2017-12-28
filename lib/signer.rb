require 'json/jwt'
require 'rest-client'
require 'digest'
require 'base64'

class SignerApi

  def self.encode_token(payload, sign_secret = ENV['SIGNER_API_SECRET'] )
    JSON::JWT.new(payload).sign(sign_secret, :HS256).to_s
  end

  def self.upload_file(file, user, organization)
    url = ENV["SIGNER_APP_HOST"]
    endpoint = '/files/tickets'
    api_token_key = ENV['SIGNER_API_TOKEN_KEY']

    payload = {
      expiration: Time.now.utc.iso8601[0...-1], #Had to remove the Z from the UTC time, because the api does not suport it.
      run: user.rut_number, #"1111111"
      purpose: 'Propósito General', # Use OTP on file sign.
      entity: organization.name #"Subsecretaría General de La Presidencia"
    }

    token = SignerApi.encode_token(payload)
    base64file = Base64.strict_encode64(file)
    checksum = Digest::SHA256.hexdigest file

    files = [
      {
        content: base64file,
        checksum: checksum,
        "content-type".to_sym => 'application/pdf',
        description: 'Convenio de Interoperabilidad'
      }
    ]

    data = {files: files, token: token, api_token_key: api_token_key}

    begin
      response = RestClient.post( url + endpoint,
        data.to_json, :content_type => :json, :accept => :json, Host: URI.parse(url).host)
      puts response.to_json
      response
    rescue => e
      puts e.response.to_json
      Rollbar.error('Upload file to Signer Service URL: ' + url +
       ' path: ' + endpoint + ' user: ' + user.name + ' organization: ' + organization.name + ' returned: ' + e.response)
      return e.response
    end
  end

  def self.sign_document(sesion_token, otp)
    url = ENV["SIGNER_APP_HOST"]
    endpoint = '/files/tickets/'

    begin
      response = RestClient.get(url + endpoint + sesion_token, OTP: otp)
      puts response.to_json
      response
    rescue => e
      puts e.response.to_json
      Rollbar.error('Sign document in Signer Service URL: ' + url +
        'path: ' + endpoint + ' sesion_token: ' + sesion_token + ' returned: ' + e.response)
      return e.response
    end
  end

end
