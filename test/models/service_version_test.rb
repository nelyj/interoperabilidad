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
    service.last_version.rejected!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.last_version.retired!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.last_version.outdated!

    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    service.last_version.current!

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
    service.last_version.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:pablito),
                                    backwards_compatible: true)
    service.last_version.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:pablito),
                                    backwards_compatible: true)
    service.last_version.reject_version
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

  test 'perform_health_check with a healthy response' do
    service_version = service_versions(:servicio1_v3)
    response_mock = Minitest::Mock.new
    response_mock.expect :code, 200
    response_body = {
      codigo_estado: 200,
      msj_estado: 'OK',
      desc_personalizada_estado: 'Everything is just peachy'
    }.to_json
    response_mock.expect :body, response_body
    service_version.stub :health_check_response, response_mock do
      service_version.perform_health_check!
    end
    assert_mock response_mock
    last_check = service_version.service_version_health_checks.last
    assert_equal 200, last_check.http_status
    assert_equal response_body, last_check.http_response
    assert_equal 200, last_check.status_code
    assert_equal 'OK', last_check.status_message
    assert_equal 'Everything is just peachy', last_check.custom_status_message
  end

  test 'perform_health_check with a error response' do
    service_version = service_versions(:servicio1_v3)
    response_mock = Minitest::Mock.new
    response_mock.expect :code, 500
    response_body = {
      codigo_estado: 500,
      msj_estado: 'Server Error',
      desc_personalizada_estado: 'Cannot connect to the database'
    }.to_json
    response_mock.expect :body, response_body
    service_version.stub :health_check_response, response_mock do
      service_version.perform_health_check!
    end
    assert_mock response_mock
    last_check = service_version.service_version_health_checks.last
    assert_equal 500, last_check.http_status
    assert_equal response_body, last_check.http_response
    assert_equal 500, last_check.status_code
    assert_equal 'Server Error', last_check.status_message
    assert_equal 'Cannot connect to the database', last_check.custom_status_message
  end

  test 'perform_health_check without a response at all' do
    service_version = service_versions(:servicio1_v3)
    service_version.stub :health_check_response, -> { raise Errno::ECONNREFUSED.new } do
      service_version.perform_health_check!
    end
    last_check = service_version.service_version_health_checks.last
    assert_equal(-1, last_check.http_status)
    assert_nil last_check.http_response
    assert_equal(-1, last_check.status_code)
    assert_not_nil last_check.status_message
    assert_nil last_check.custom_status_message
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
