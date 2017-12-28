class Role <ApplicationRecord
  belongs_to :user
  belongs_to :organization

  def self.get_organization_users(the_organization, the_role)
    response = RoleService.get_organization_users(the_organization, the_role)

    if response.code == 200
      response = JSON.parse(response)
      Role.parse_persons(response["personas"], the_role, the_organization)
    else
      Rollbar.error('Call to Role Service for organization: ' + the_organization.name +
        ' role: ' + the_role + ' Returned: ' + response.code.to_s)
      return nil
    end
  end

  def self.parse_persons(persons, role, org)
    users = Array.new
    return [{name: "", email: [""]}] if persons.nil?
    persons.map do |p|
      first_name = p["nombre"]["nombres"].join(' ')
      last_name = p["nombre"]["apellidos"].join(' ')
      name = first_name.strip + ' ' + last_name.strip

      emails = Array.new
      last_email = ""
      p["instituciones"].map do |i|
        if i["institucion"]["id"] == org.dipres_id && i["rol"] == role
          emails << i["email"]
        end
      end

      users << {name: name, email: emails}
    end
    users
  end


end
