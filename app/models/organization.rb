class Organization <ApplicationRecord
  has_many :roles
  has_many :users, through: :roles
  has_many :services
  has_many :agreements

  def to_param
    name
  end

  def can_create_service_or_version?(user)
    user.roles.where(organization: self).exists?(name: "Service Provider")
  end

  def is_member?(user)
    user.organizations.exists?(dipres_id: self.dipres_id)
  end

  def can_create_agreement?(user)
    user.roles.exists?(['name = ? AND organization_id <> ?', "Create Agreement", self.id ])
  end

end
