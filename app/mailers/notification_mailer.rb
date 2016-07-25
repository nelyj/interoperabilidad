class NotificationMailer < ApplicationMailer
  default from: 'notificaciones@interoperabilidad.digital.gob.cl'

  def notify(notification)
    if notification.subject_type == "ServiceVersion"
      email = notification.email
      @notification  = notification
      mail(to: email, subject: t(:service_type_notification))
    else
    end
  end
end
