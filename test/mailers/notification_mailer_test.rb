require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase

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

end
