class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :subject, polymorphic: true
  after_create :send_by_email
  default_scope -> { order('created_at DESC') }

  # Add on AgreementVersion: has_many :notifications, as: :subject

  def send_by_email
    NotificationMailer.notify(self).deliver_now unless email.blank?
  end

  # Should be called by NotificationController#index
  def mark_as_seen
    self.update(seen: true)
  end

  # Should be called by NotificationController#show
  def mark_as_read
    # It can't be read without seeing it
    self.update(read: true, seen: true)
  end
end
