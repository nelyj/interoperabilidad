require 'uri'
require 'net/http'

module RolesHelper

  CONSOLE_URL = ENV['ROLE_SERVICE_URL']
  CLIENT_ID = ENV['ROLES_CONSOLE_CLIENT_ID'] || '0582440979aa4ba988533870938a82dc'
  CLIENTE_SECRET = ENV['ROLES_CONSOLE_CLIENT_SECRET'] || '6167b53dadb44abda97edc304e3ef23d'
  SCOPE = ENV['ROLE_CONSOLE_SCOPE']
  GRANT_TYPE = ENV['ROLE_CONSOLE_GRANT_TYPE']

  def request_access_token
    begin
      path = '/oauth2/token'
      uri = URI(CONSOLE_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(CONSOLE_URL + path)
      request["content-type"] = 'multipart/form-data'
      request.set_form_data(
        client_id: CLIENT_ID,
        client_secret: CLIENTE_SECRET,
        scope: SCOPE,
        grant_type: GRANT_TYPE
      )

      body = http.request(request).read_body
      JSON.parse(body)['access_token']

    rescue => e
      Rollbar.error('Call to Role Service URL: ' + CONSOLE_URL +
       ' path: ' + path + ' returned: ' + e.to_s)
      return e.to_s
    end
  end

  def request_user_info(rut)
    path = '/api/apps/1/usuarios/' + rut.strip
    uri = URI(CONSOLE_URL + path)
    params = {access_token: request_access_token}
    uri.query = URI.encode_www_form(params)

    puts uri.to_s
    request = Net::HTTP.get_response(uri)
    JSON.parse(request.body)

  end
end
