class User < ApplicationRecord
  has_many :roles
  has_many :organizations, through: :roles
  has_many :service_versions
  has_many :schema_versions

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

  GOB_DIGITAL_ID = "AB01"

  URL = ENV['ROLE_SERVICE_URL']
  APP_ID = ENV['ROLE_APP_ID']

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
    new_user.refresh_user_roles_and_email(auth.extra.raw_info)
    new_user
  end

  def refresh_user_roles_and_email(raw_info)
    response = call_roles_service(URL)
    if response.nil?
      Rollbar.error('Call to Role Service for user: ' + name +
       ' rut: ' + rut_number + ' Returned: nil')
       parse_organizations_and_roles(nil, raw_info)
    else
      if response.code == 200
        response = JSON.parse(response)
        parse_organizations_and_roles(response, raw_info)
        save!
      else
        Rollbar.error('Call to Role Service for user: ' + name +
        ' rut: ' + rut_number + ' Returned: ' + response.code.to_s)
        parse_organizations_and_roles(nil, raw_info)
      end
    end
  end

  def parse_organizations_and_roles(response, raw_info)
    self.roles.delete_all
    self.can_create_schemas = false
    if response.nil? || response.has_key?('nada')
      self.name = raw_info.nombres + ' ' + raw_info.apellidoPaterno + ' ' + raw_info.apellidoMaterno
    else
      self.name = refresh_name(response['nombre'])
      response['instituciones'].each do |organization|
        org = organization['institucion']
        role = organization['rol']
        email = parse_email(organization['email'])
        parse_organization_role(org, role, email)
      end
    end
  end

  def parse_organization_role(organization, role, email)
    org_id = organization['id']
    self.can_create_schemas = (org_id == GOB_DIGITAL_ID)
    org = Organization.where(dipres_id: org_id ).first_or_create!(
      name: organization['nombre'].empty? ?
              'Secretaría General de la Presidencia' : organization['nombre'],
      initials: organization['sigla'].empty? ?
              'SEGPRES' : organization['sigla'])
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
    begin
      RestClient.get(url + path)
    rescue => e
      Rollbar.error('Call to Role Service URL: ' + URL +
       ' path: ' + path + ' returned: ' + e.response)
       return nil
    end
  end

  def rut_number
    return self.rut[0..-3].tr('.','')
  end

  def is_service_admin?
    gob_digital = Organization.where(dipres_id: GOB_DIGITAL_ID)
    belongs_to_gobdigital = organizations.exists?(gob_digital)
    is_service_provider = roles.where(organization: gob_digital).exists?(name: "Service Provider")
    return false unless belongs_to_gobdigital && is_service_provider
    return true
  end

end
