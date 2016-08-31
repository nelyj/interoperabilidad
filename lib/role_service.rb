require 'rest-client'

class RoleService

  def self.get_organization_users(org, role)
    path = '/instituciones/' + URI.encode(org.initials) +
      '/roles/' + URI.encode(role) + '/aplicaciones/' + URI.encode(ENV['ROLE_APP_ID'])
    RoleService.get_data(path)
  end

  def self.get_user_info(rut_number)
    path = '/personas/' + URI.encode(rut_number) +
      '/aplicaciones/' + URI.encode(ENV['ROLE_APP_ID'])
    RoleService.get_data(path)
  end

  def self.get_data(path)
    url = ENV['ROLE_SERVICE_URL']
    begin
      RestClient.get(url + path)
    rescue => e
      Rollbar.error('Call to Role Service URL: ' + url +
       ' path: ' + path + ' returned: ' + e.response)
      return e.response
    end
  end

end
