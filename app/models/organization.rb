class Organization <ApplicationRecord
  #One organization have many user with many roles
  has_many :roles
  has_many :users, through: :roles
end
