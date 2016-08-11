class User < ApplicationRecord
  has_many :roles, dependent: :delete_all
  has_many :organizations, through: :roles
  has_many :service_versions
  has_many :schema_versions
  has_many :notifications
  has_many :agreement_versions

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
      name: organization['nombre'],
      initials: organization['sigla'])
    self.roles.create(organization: org, name: parse_role(role), email: email)
  end

  def parse_role(role)
    case role
      when "Validador"
        "Service Provider"
      when "1"
        "Create Agreement"
      when "2"
        "Sign Agreement"
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

  def unread_notifications
    self.notifications.where(read: false).count
  end

  def unseen_notifications?
    self.notifications.exists?(seen: false)
  end

  def agreement_creation_organization(service)
    organizations_where_can_create_agreements(service).first
  end

  def can_create_agreements_to_many_organizations?(service)
    organizations_where_can_create_agreements(service).count > 1
  end

  def organizations_where_can_create_agreements(service)
    array = [service.organization_id]
    organizations.find_each do |org|
      array << org.id if org.has_agreement_for?(service)
    end
    organizations.where(['roles.name = ? AND roles.organization_id NOT IN (?)',"Create Agreement", array])
  end

  def organizations_with_agreement?(service)
    service.agreements.exists?(service_consumer_organization: self.organization_ids)
  end

  def organizations_have_agreements_for_all_orgs(service)
    return true if service.public
    organizations.find_each do |org|
      return false unless org.has_agreement_for?(service)
    end
    return true
  end

end
