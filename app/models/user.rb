require './lib/role_service.rb'

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

  GOB_DIGITAL_ID = ENV['MINSEGPRES_DIPRES_ID']

  URL = ENV['ROLE_SERVICE_URL']
  APP_ID = ENV['ROLE_APP_ID']

  def self.from_omniauth(auth)
    rut = self.rut_with_separator(auth.extra.raw_info.RolUnico)
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

  def self.rut_with_separator(rut_object)
    rut = rut_object.numero.to_s.reverse.scan(/\d{3}|.+/).join(".").reverse
    rut + "-" + rut_object.DV
  end

  def refresh_user_roles_and_email(raw_info)
    response = RoleService.get_user_info(rut_number)
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

  def parse_organizations_and_roles(response, raw_info)
    self.roles.delete_all
    self.can_create_schemas = false
    if response.nil? || response.has_key?('nada')
      self.name = raw_info.name.nombres.join(' ') + ' ' + raw_info.name.apellidos.join(' ')
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
    org.update(
      name: organization['nombre'],
      initials: organization['sigla'],
      address: organization['direccion']
      )
    self.roles.create(organization: org, name: role, email: email)
  end

  def parse_email(email)
    email = email.empty? ? "mail@example.org" : email
  end

  def refresh_name(full_name)
    first_name = full_name['nombres'].join(' ')
    second_name = full_name['apellidos'].join(' ')
    name = first_name.strip + ' ' + second_name.strip
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

  def can_create_agreements?(org)
    roles.where(organization: org, name: "Create Agreement").exists?
  end

  def can_see_client_token_for_service?(service)
    !service.public && self.organizations.include?(service.organization)
  end

  def can_see_provider_secret_for_service?(service)
    return false if service.public # No secrets there
    return true if service.service_versions.where(version_number: 1).first.user == self # Original creator can see the secret
    # And validators and signers of agreements can also see secrets
    org = service.organization
    return (
      self.roles.where(organization: org, name: "Validate Agreement").exists? ||
      self.roles.where(organization: org, name: "Sign Agreement").exists?
    )
  end

  def can_see_credentials_for_agreement?(agreement)
    return false unless agreement.signed?
    return true if agreement.agreement_revisions.where(revision_number: 1).first.user == self  # The person who started the agreement can see the secret
    # And validators and signers of agreements can also see secrets
    org = agreement.consumer_organization
    return (
      self.roles.where(organization: org, name: "Validate Agreement").exists? ||
      self.roles.where(organization: org, name: "Sign Agreement").exists?
    )
  end

  def can_try_protected_service?(service)
    return true if self.organizations.include?(service.organization)
    service.agreements.where(service_consumer_organization: self.organization_ids).any?(&:signed?)
  end

end
