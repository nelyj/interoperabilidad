class User < ApplicationRecord
  has_many :roles
  has_many :organizations, through: :roles
  has_many :service_versions

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

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
    self.can_create_schemas = true
    self.name = "Perico"
    self.email = "mail@example.org"
    # Organization has to be updated if it changes
    org = Organization.where(initials: 'SEGPRES').first_or_create!(
      name: 'Secretaría General de la Presidencia',
      initials: 'SEGPRES')
    self.roles.where(organization: org).delete_all
    self.roles.first_or_create!(organization: org, name: "Service Provider")
    save!
  end
end
