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

    puts service.service_versions.length
    puts service.service_versions.rejected.length
    puts service.service_versions.retired.length
    puts service.service_versions.outdated.length
    puts service.service_versions.current.length
    puts service.service_versions.retracted.length
    puts service.service_versions.proposed.length

    assert_equal 6, service.service_versions.length
    assert_equal 1, service.service_versions.rejected.length
    assert_equal 1, service.service_versions.retired.length
    assert_equal 1, service.service_versions.outdated.length
    assert_equal 1, service.service_versions.current.length
    assert_equal 1, service.service_versions.retracted.length
    assert_equal 1, service.service_versions.proposed.length
  end

end
