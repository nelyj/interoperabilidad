require 'test_helper'

class ServiceVersionTest < ActiveSupport::TestCase

  test 'validations' do
    # VALID_SPEC and INVALID_SPEC are loaded by test_helper
    valid_service_version = ServiceVersion.new(
      spec_file: StringIO.new(VALID_SPEC), service: services(:servicio_1), user: users(:perico))
    invalid_service_version = ServiceVersion.new(
      spec_file: StringIO.new(INVALID_SPEC), service: services(:servicio_2), user: users(:perico))
    assert valid_service_version.valid?
    assert_not invalid_service_version.valid?
    assert_not invalid_service_version.errors[:spec].blank?
  end

  test '#retract_proposed create 3 new versions for a '\
       'Service and only the last one have to be proposed.' do
    service = services(:servicio_1)
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico))
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    assert_equal 6, service.service_versions.length
    assert_equal 5, service.service_versions.retracted.length
    assert_equal 1, service.service_versions.proposed.length
  end

  test '#retract_proposed create new versions for a '\
       'Service and only the 3 proposed shuld be modified.' do
    service = services(:servicio_1)
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico))
    service.service_versions.last.rejected!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.service_versions.last.retired!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.service_versions.last.outdated!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.service_versions.last.current!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))

    assert_equal 9, service.service_versions.length
    assert_equal 1, service.service_versions.rejected.length
    assert_equal 1, service.service_versions.retired.length
    assert_equal 1, service.service_versions.outdated.length
    assert_equal 1, service.service_versions.current.length
    assert_equal 4, service.service_versions.retracted.length
    assert_equal 1, service.service_versions.proposed.length
  end

  test '#make_current_version create 3 versions backwards_compatible'\
        'and make each one current only one current must exist and the other'\
        'two must be outdated' do

    service = Service.create!(
      name: "Test Servicio 1",
      organization: organizations(:segpres),
      spec_file: StringIO.new(VALID_SPEC)
      )
    user = users(:pablito)
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: user,
                                     backwards_compatible: true)
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: user,
                                     backwards_compatible: true)
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: user,
                                     backwards_compatible: true)
    version.make_current_version

    assert_equal 2, service.service_versions.outdated.length
    assert_equal 1, service.service_versions.current.length
  end

  test '#make_current_version create 3 versions without backwards_compatible'\
        'and make each one current only one current must exist and the other'\
        'two must be retired' do

    service = Service.create!(
      name: "Test Servicio 1",
      organization: organizations(:segpres),
      spec_file: StringIO.new(VALID_SPEC)
      )
    user = users(:pablito)

    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: user)
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: user)
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: user)
    version.make_current_version
    assert_equal 2, service.service_versions.retired.length
    assert_equal 1, service.service_versions.current.length
  end

  test '#reject_version create 3 versions and reject them all 3 must be rejected' do
    service = services(:servicio_1)
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:pablito),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:pablito),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:pablito),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    assert_equal 3, service.service_versions.rejected.length
  end

  test "generate_zipped_code returns an URL where the code can be downloaded" do
    service = services(:servicio_1)
    service_version = service.service_versions.create!(
      spec_file: StringIO.new(VALID_SPEC),
      service: service,
      user: users(:pablito),
      backwards_compatible: true
    )
    url = service_version.generate_zipped_code(%w(java php csharp jaxrs-cxf slim aspnet5))
    assert !open(url).read.nil?
  end

  test ".make_current_version take a proposed version an makes it approved and send a notification" do
    #def make_current_version
    #self.current!
    #update_old_versions_statuses
    #create_state_change_notification(I18n.t(:approved))

  end

  test ".reject_version take a proposed version an makes it rejected and send a notification" do
    #def reject_version
    #self.rejected!
    #create_state_change_notification(I18n.t(:rejected))
  end

  test ".create_new_notification generates a new notification about the service_version" do
    #def create_new_notification
    #org = Organization.where(dipres_id: "AB01")
    #if version_number == 1
    #  message = I18n.t(:create_new_service_notification, name: name)
    #else
    #  message = I18n.t(:create_new_version_notification, name: name, version: version_number.to_s)
    #end
    #Role.where(name: "Service Provider", organization: org).each do |role|
    #  role.user.notifications.create(subject: self,
    #    message: message
    #  )
    #end
  end

  test ".create_state_change_notification create a state change notification about to the service_version" do
    #def create_state_change_notification(status)
    #org = Organization.where(dipres_id: "AB01")
    #user.notifications.create(subject: self,
    #  message: I18n.t(:create_state_change_notification, name: name,
    #    version: self.version_number.to_s, status: status)
    #)
  end

  test ".retract_proposed mark al notification of older proposed versions as readed" do
    #def retract_proposed
    #service.service_versions.proposed.where(
    #  "version_number != ?", self.version_number).each do |version|
    #
    #    version.update(status: ServiceVersion.statuses[:retracted])
    #    version.notifications.update_all(read: true)
    #end
  end

end
