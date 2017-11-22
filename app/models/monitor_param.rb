class MonitorParam < ApplicationRecord
  belongs_to :organization
  validates :organization, uniqueness: true
end
