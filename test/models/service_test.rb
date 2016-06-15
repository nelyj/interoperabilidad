require 'test_helper'

class ServiceTest < ActiveSupport::TestCase

  def create_valid_service!
    Service.create!(
      organization: organizations(:segpres),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC)
    )
  end

  test '#last_version returns the version number of the last service version' do
    service = create_valid_service!
    service.create_first_version(users(:perico))
    assert_equal 1, service.last_version_number
    # VALID_SPEC is loaded by test_helper
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico))
    assert_equal 2, service.last_version_number
    service.service_versions.create(spec_file: StringIO.new(VALID_SPEC), user: users(:perico))
    assert_equal 3, service.last_version_number
  end

  test "#can_be_updated_by? returns true for a user who belongs to the service's organization" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:segpres), name: "Whatever")
    assert service.can_be_updated_by?(perico)
  end

  test "#can_be_updated_by? returns false for a user who does not belong to the service's organization" do
    service = create_valid_service!
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not service.can_be_updated_by?(perico)
  end
end
