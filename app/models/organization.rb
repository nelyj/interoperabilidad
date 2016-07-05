class Organization <ApplicationRecord
  has_many :roles
  has_many :users, through: :roles
  has_many :services

  def to_param
    name
  end
end
