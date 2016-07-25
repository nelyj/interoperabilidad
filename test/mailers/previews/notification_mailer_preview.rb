class NotificationMailerPreview < ActionMailer::Preview
  def notify
    NotificationMailer.notify(Notification.first)
  end
end
