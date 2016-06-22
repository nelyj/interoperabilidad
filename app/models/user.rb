class User < ApplicationRecord
  has_many :roles
  has_many :organizations, through: :roles
  has_many :service_versions

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

  URL = ENV['ROLE_URL'] || 'http://private-5f0326-microserviciosderolesv4.apiary-mock.com/v1/'
  APP_ID = ENV['ROLE_APP_ID'] || 0

  def self.from_omniauth(auth)
    rut = auth.extra.raw_info.RUT
    sub = auth.extra.raw_info.sub
    id_token = auth.credentials.id_token
    new_user = where(rut: rut).first
    if new_user.nil?
      new_user = create!(rut: rut, sub: sub, id_token: id_token)
    else
      new_user.update!(sub: sub, id_token: id_token)
    end
    new_user.refresh_user_roles_and_email!
    new_user
  end

  # TODO: need to be changed later, to use the provided service to get the roles.
  def refresh_user_roles_and_email!
    response = JSON.parse(call_roles_service)
    self.name = refresh_name(response['nombre'])
    parse_organizations_and_roles(response['instituciones'])

    self.can_create_schemas = true
    save!
  end

  def parse_organizations_and_roles(organizations)
    organizations.each do |organization|
      org = organization['institucion']
      role = organization['rol']
      email = parse_email(organization['email']['email'])
      parse_organization_role(org, role, email)
    end
  end

  def parse_organization_role(organization, role, email)
    org_id = organization['id'].length > 0 ? organization['id'] : "31"
    org = Organization.where(dipres_id: org_id ).first_or_create!(
      name: organization['nombre'].length > 0 ?
              organization['nombre'] : 'Secretaría General de la Presidencia',
      initials: organization['sigla'].length > 0 ?
              organization['sigla'] : 'SEGPRES')

    self.roles.where(organization: org).delete_all
    self.roles.first_or_create!(organization: org, name: parse_role(role), email: email)
  end

  def parse_role(role)
    case role
      when "0"
        "Service Provider"
      when "1"
        "Can Check Agreement"
      when "2"
        "Can Sign Agreement"
      else
        "Service Provider"
      end
  end

  def parse_email(email)
    email = email.length > 1 ? email : "mail@example.org"
  end

  def refresh_name(full_name)
    first_name = ''
    full_name['nombres'].each do |name|
      first_name += name + ' '
    end

    second_name = ''
    full_name['apellidos'].each do |name|
      second_name += name + ' '
    end

    first_name = 'Perico' unless first_name.length >= 1
    second_name = 'de los Palotes' unless second_name.length >= 1

    name = first_name.strip + ' ' + second_name.strip
  end

  def call_roles_service
    path = 'personas/' + self.rut.to_s + '/apps/' + APP_ID.to_s
    response = RestClient.get(URL + path)
  end

end
