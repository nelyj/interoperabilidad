require 'json/jwt'
require 'rest-client'
require 'digest'

class SignerApi

  def self.encode_token(payload)
    JSON::JWT.new(payload).sign(ENV['SIGNER_API_SECRET'], :HS256).to_s
  end

  def self.upload_file(file)
    url = 'http://proxy-banco.modernizacion.gob.cl'
    endpoint = '/files/tickets'
    api_token_key = ENV['SIGNER_API_TOKEN_KEY']
    payload = {
      expiration: '2016-06-15T17:31:00',#"2016­06823T17:31:00",
      rut: '22222222',
      proposito: 'Propósito General',
      entidad: 'Subsecretaría General de La Presidencia'
    }
    token = SignerApi.encode_token(payload)

    #pdf = File.read("#{Rails.root}/lib/content.txt")
    pdf = File.read("#{Rails.root}/lib/api_firma_base64.txt")

    #a = File.read("#{Rails.root}/lib/content_checksum.txt")
    a = File.read("#{Rails.root}/lib/api_firma_checksum.txt")
    puts a
    checksum = Digest::SHA256.hexdigest pdf
    puts checksum
    files = [
      {
        content: pdf,
        checksum: checksum,
        type: 'PDF',
        description: 'Prueba1'
      }
    ]

    data = {files: files, token: token, api_token_key: api_token_key}
    #puts '************************************************************'
    #puts data.to_json
    #puts File.read("#{Rails.root}/lib/api_firma_checksum.txt")
    #puts '************************************************************'
    begin
      RestClient.post( url + endpoint,
        data.to_json, :content_type => :json, :accept => :json, Host: 'proxy-banco.modernizacion.gob.cl')
    rescue => e
      Rollbar.error('Call to Role Service URL: ' + url +
       ' path: ' + endpoint + ' returned: ' + e.response)
      return e
    end
  end

  def self.sign_document(sesion_token, otp)
    url = 'http://proxy-banco.modernizacion.gob.cl'
    endpoint = '/files/tickets/'
    api_token_key = ENV['SIGNER_API_TOKEN_KEY']

    #sesion_token = '57c055f63c3d230bd2e030c5'

    RestClient.get(url + endpoint + sesion_token, OTP: otp)
  end

end
