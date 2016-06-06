class Role <ApplicationRecord
  #One role belongs to a user and an organization.
  belongs_to :user
  belongs_to :organization
end
