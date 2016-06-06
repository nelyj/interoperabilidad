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
    end
  end
end
