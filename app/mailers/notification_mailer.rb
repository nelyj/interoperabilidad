class NotificationMailer < ApplicationMailer
  default from: 'notifications@dev.interoperabilidad.digital.gob.cl'

  def notify(notification)
    if notification.subject_type == "ServiceVersion"
      email = notification.email
      @url  = 'http://dev.interoperabilidad.digital.gob.cl'
      mail(to: email, subject: 'New Notification')
    else
    end
  end
end
