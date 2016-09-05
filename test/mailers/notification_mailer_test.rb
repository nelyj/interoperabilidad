require 'test_helper'
require "#{Rails.root}/test/features/support/agreement_creation_helper"
class NotificationMailerTest < ActionMailer::TestCase
  include AgreementCreationHelper

  test "Send Email" do
    email = NotificationMailer.notify(notifications(:servicio_2_created_notification))

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['notificaciones@interoperabilidad.digital.gob.cl'], email.from
    assert_equal ['mail@example.org'], email.to
    assert_equal 'Nueva notificacion de Servicios', email.subject
    assert email.text_part.body.decoded.include?('Mensaje de Prueba')
  end

  test "Invalid subject" do
    email = NotificationMailer.notify(notifications(:subject_invalido))

    assert_emails 0 do
      email.deliver_now
    end

    assert_nil email.from
    assert_nil email.to
    assert_nil email.subject
    assert_equal '', email.body.to_s
  end

  test "Agreement Notification" do
    agreement = create_valid_agreement!(organizations(:sii), organizations(:segpres))
    notif = Notification.create(
      user: users(:pedro),
      subject: agreement.last_revision,
      subject_type: "AgreementRevision",
      message: "Mensaje de Prueba",
      read: false,
      seen: false,
      email: "mail@example.org"
    )
    email = NotificationMailer.notify(notif)
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['notificaciones@interoperabilidad.digital.gob.cl'], email.from
    assert_equal ['mail@example.org'], email.to
    assert_equal 'Nueva notificacion de Convenios', email.subject
    assert email.text_part.body.decoded.include?('Mensaje de Prueba')
  end

end
