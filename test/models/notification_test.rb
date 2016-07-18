require 'test_helper'

class NotificationTest < ActiveSupport::TestCase

  test ".send_by_email send an email to the user every time a notification is created" do
  end

  test ".mark_as_seen mark a notification as seen" do
    notification = Notification.create(user: users(:pedro), subject: Service.first, message: "")
    assert_not notification.seen
    notification.mark_as_seen
    assert notification.seen
  end

  test ".mark_as_read mark a notification as readed" do
    notification = Notification.create(user: users(:pedro), subject: Service.first, message: "")
    assert_not notification.read
    notification.mark_as_read
    assert notification.seen
    assert notification.read
  end

end
