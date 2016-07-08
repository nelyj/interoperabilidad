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
    assert_equal 3, service.service_versions.length
    assert_equal 2, service.service_versions.retracted.length
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

    assert_equal 6, service.service_versions.length
    assert_equal 1, service.service_versions.rejected.length
    assert_equal 1, service.service_versions.retired.length
    assert_equal 1, service.service_versions.outdated.length
    assert_equal 1, service.service_versions.current.length
    assert_equal 1, service.service_versions.retracted.length
    assert_equal 1, service.service_versions.proposed.length
  end

  test '#make_current_version create 3 versions backwards_compatible'\
        'and make each one current only one current must exist and the other'\
        'two must be outdated' do
    org = Organization.create!(
      name: "Secretaría General de la Presidencia",
      initials: "ASDR",
      dipres_id: "ASDF31"
      )
    service = Service.create!(
      name: "Test Servicio 1",
      organization: org,
      spec_file: StringIO.new(VALID_SPEC)
      )
    user = User.create!(
      name: 'Perico de los Palotes',
      rut: "33.333.333-3",
      sub: "9",
      id_token: "some-token"
      )
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
    org = Organization.create!(
      name: "Secretaría General de la Presidencia",
      initials: "ASDR",
      dipres_id: "ASDF31"
      )
    service = Service.create!(
      name: "Test Servicio 1",
      organization: org,
      spec_file: StringIO.new(VALID_SPEC)
      )
    user = User.create!(
      name: 'Perico de los Palotes',
      rut: "33.333.333-3",
      sub: "9",
      id_token: "some-token"
      )

    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                     user: users(:perico))
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico))
    version.make_current_version
    version = service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico))
    version.make_current_version
    assert_equal 2, service.service_versions.retired.length
    assert_equal 1, service.service_versions.current.length
  end

  test '#reject_version create 3 versions and reject them'\
        'all 3 must be rejected' do
    service = services(:servicio_1)
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    service.service_versions.create!(spec_file: StringIO.new(VALID_SPEC),
                                     service: service,
                                    user: users(:perico),
                                    backwards_compatible: true)
    service.service_versions.last.reject_version
    assert_equal 3, service.service_versions.rejected.length
  end

  test "generate_zipped_code returns an URL where the code can be downloaded" do
    service = services(:servicio_1)
    service_version = service.service_versions.create!(
      spec_file: StringIO.new(VALID_SPEC),
      service: service,
      user: users(:perico),
      backwards_compatible: true
    )
    url = service_version.generate_zipped_code(%w(java php csharp spring slim aspnet5))
    assert !open(url).read.nil?
  end

end
