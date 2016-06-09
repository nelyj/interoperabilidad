require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test '#refresh_user_roles_and_email! sets a hard coded email, org, flags and roles' do
    user = users(:perico)
    segpres = organizations(:segpres)
    user.refresh_user_roles_and_email!
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organizations.first
    assert user.can_create_schemas
    assert "Schema Admin", user.roles.where(organization: segpres).first.name
  end

  test '.from_omniauth set Auth params to new user' do
    module LookLikeJSON
      def method_missing(meth, *args, &block)
        if has_key?(meth.to_s)
          self[meth.to_s]
        else
          raise NoMethodError, 'undefined method #{meth} for #{self}'
        end
      end
    end

    info = { "rut" => "22.222.222-2", "sub" => "8", "id_token" => "ASDF" }
    info.extend(LookLikeJSON)
    auth = {"info" => info}
    auth.extend(LookLikeJSON)

    User.from_omniauth(auth)
    user = User.where(rut: auth.info.rut).first
    segpres = organizations(:segpres)

    assert_equal "22.222.222-2", user.rut
    assert_equal "8", user.sub
    assert_equal "ASDF", user.id_token
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organizations.first
    assert user.can_create_schemas
    assert "Schema Admin", user.roles.where(organization: segpres).first.name
  end
end
