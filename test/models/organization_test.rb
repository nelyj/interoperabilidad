require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase

  test "#can_create_service_or_version? returns true for a user who belongs to the organization" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert organizations(:sii).is_member?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who does not belongs to the organization" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not organizations(:segpres).is_member?(perico)
  end

  test "#can_create_service_or_version? returns true for a user who belongs to the organization and is Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Service Provider")
    assert organizations(:sii).can_create_service_or_version?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who belongs to the organization and is not a Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not organizations(:sii).can_create_service_or_version?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who does not belongs to the organization and is Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Service Provider")
    assert_not organizations(:segpres).can_create_service_or_version?(perico)
  end

  test "#can_create_service_or_version? returns false for a user who does not belongs to the organization and is not a Service Provider" do
    perico = users(:perico)
    perico.roles.create!(organization: organizations(:sii), name: "Whatever")
    assert_not organizations(:segpres).can_create_service_or_version?(perico)
  end

end
