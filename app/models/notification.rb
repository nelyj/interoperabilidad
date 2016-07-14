class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :subject, polymorphic: true
  after_create :send_by_email
  default_scope -> { order('created_at DESC') }

  # Add on AgreementVersion: has_many :notifications, as: :subject

  def send_by_email
    # Use a mailer http://guides.rubyonrails.org/action_mailer_basics.html
    #
    # Important: The email link should point to user_notification_url(user, notification)
    #
    # And then the notification controller should call 'mark_as_read'
    # before redirecting to 'subject.url'
    # ServiceVersion, AgreementVersion, etc should implement an 'url' method
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
