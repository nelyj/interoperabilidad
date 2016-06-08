class User < ApplicationRecord
  has_many :roles
  has_many :organizations, through: :roles

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

  def self.from_omniauth(auth)
    new_user = where(rut: auth.info.rut).first_or_create! do |user|
      user.sub = auth.info.sub
      user.id_token = auth.info.id_token
    end
    new_user.add_role_from_service!
  end

  # TODO: need to be changed later, to use the provided service to get the roles.
  def refresh_user_roles_and_email!
    self.can_create_schemas = true
    self.email = "mail@example.org"
    # Organization has to be updated if it changes
    org = Organization.find_by_initials("SEGPRES")
    self.roles.first_or_create!(organization: org, name: "Schema Admin")
    save!
  end
end
