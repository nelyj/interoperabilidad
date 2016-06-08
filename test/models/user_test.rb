require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test '#refresh_user_roles_and_email! sets a hard coded email, org, flags and roles' do
    user = users(:perico)
    segpres = organizations(:segpres)
    user.refresh_user_roles_and_email!
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organization
    assert user.can_create_schemas
    assert "Schema Admin", user.roles.where(organization: segpres).first.name
  end
end
