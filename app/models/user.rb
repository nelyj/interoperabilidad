class User < ApplicationRecord
  # One user may belong to many organizations,
  # and have many roles.
  has_many :roles
  has_many :organizations, through: :roles

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :omniauthable, omniauth_providers: [:clave_unica]

  def self.from_omniauth(auth)
    puts "#{auth.inspect}"
    where(rut: auth.info.rut).first_or_create! do |user|
      user.sub = auth.info.sub
      user.id_token = auth.info.id_token
      add_role_from_service!(user)
    end
  end

  def add_role_from_service!(user)
    user.can_create_schemas = true
    org = Organization.find_by_initials("SEGPRES")
    rol = Role.first_or_create(user_id: user.id,
                               organization_id: org.id,
                               name: "Schema Admin")
    user.save
  end

end
