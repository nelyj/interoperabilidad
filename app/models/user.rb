class User < ApplicationRecord
  has_many :roles
  has_many :organizations, through: :roles
  has_many :service_versions
  has_many :schema_versions

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

  FALLBACK_URL = 'http://private-5f0326-microserviciosderolesv4.apiary-mock.com'
  URL = ENV['ROLE_SERVICE_URL'] || 'http://thawing-shore-28727.herokuapp.com'
  APP_ID = ENV['ROLE_APP_ID'] || 'AB01'

  def self.from_omniauth(auth)
    new_user = where(rut: auth.info.rut).first_or_create! do |user|
      user.sub = auth.info.sub
      user.id_token = auth.info.id_token
    end
    new_user.update(sub: auth.info.sub, id_token: auth.info.id_token)
    new_user.refresh_user_roles_and_email!
    new_user
  end

  def refresh_user_roles_and_email!
    response = call_roles_service(URL)
    if response.code == 200
      response = JSON.parse(response)
      if response.has_key?('nada')
        response = JSON.parse(call_roles_service(FALLBACK_URL))
      else
        response
      end
    else
      response = JSON.parse(call_roles_service(FALLBACK_URL))
    end

    self.name = refresh_name(response['nombre'])
    parse_organizations_and_roles(response['instituciones'])

    self.can_create_schemas = true
    save!
  end

  def parse_organizations_and_roles(organizations)
    organizations.each do |organization|
      org = organization['institucion']
      role = organization['rol']
      email = parse_email(organization['email'])
      parse_organization_role(org, role, email)
    end
  end

  def parse_organization_role(organization, role, email)
    org_id = organization['id'].empty? ? "AB01" : organization['id']
    org = Organization.where(dipres_id: org_id ).first_or_create!(
      name: organization['nombre'].empty? ?
              'Secretaría General de la Presidencia' : organization['nombre'],
      initials: organization['sigla'].empty? ?
              'SEGPRES' : organization['sigla'])

    self.roles.where(organization: org).delete_all
    self.roles.first_or_create!(organization: org,
                                name: parse_role(role),
                                email: email)
  end

  def parse_role(role)
    case role
      when "Validador"
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
    email = email.empty? ? "mail@example.org" : email
  end

  def refresh_name(full_name)
    first_name = full_name['nombres'].join(' ')
    second_name = full_name['apellidos'].join(' ')

    first_name = 'Perico' if first_name.empty?
    second_name = 'de los Palotes' if second_name.empty?

    name = first_name.strip + ' ' + second_name.strip
  end

  def call_roles_service(url)
    path = '/personas/' + rut_number +
      '/instituciones/segpres/aplicaciones/' + APP_ID.to_s
    RestClient.get(url + path)
  end

  def rut_number
    return self.rut[0..-3].tr('.','')
  end

end
