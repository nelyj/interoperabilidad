class NotificationMailer < ApplicationMailer
  default from: 'notificaciones@interoperabilidad.digital.gob.cl'

  def notify(notification)
    email = notification.email
    @notification  = notification
    case notification.subject_type
    when "ServiceVersion"
      mail(to: email, subject: t(:service_type_notification))
    when "AgreementRevision"
      mail(to: email, subject: t(:agreement_type_notification))
    end
  end

end
