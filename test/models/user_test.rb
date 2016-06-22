require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test '#refresh_user_roles_and_email! sets a hard coded email, org, flags and roles' do
    user = users(:perico)
    segpres = organizations(:segpres)
    user.refresh_user_roles_and_email!
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organizations.first
    assert user.can_create_schemas
    assert "Service Provider", user.roles.where(organization: segpres).first.name
  end

  test '.from_omniauth sets Auth params to new user' do
    auth = Hashie::Mash.new(
      extra: {raw_info: {"RUT" => "22.222.222-2", "sub" => "8"}},
      credentials: {id_token: "ASDF"}
    )
    User.from_omniauth(auth)
    user = User.where(rut: "22.222.222-2").first
    segpres = organizations(:segpres)

    assert_equal "22.222.222-2", user.rut
    assert_equal "Perico", user.name
    assert_equal "8", user.sub
    assert_equal "ASDF", user.id_token
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organizations.first
    assert user.can_create_schemas
    assert "Service Provider", user.roles.where(organization: segpres).first.name
  end

  test '.from_omniauth sets Auth params to existing user' do
    auth = Hashie::Mash.new(
      extra: {raw_info: {"RUT" => "11.111.111-1", "sub" => "8"}},
      credentials: {id_token: "ASDF"}
    )
    user = User.where(rut: "11.111.111-1").first
    assert_equal "11.111.111-1", user.rut
    assert_equal "2", user.sub
    assert_equal "some-token", user.id_token

    User.from_omniauth(auth)

    user = User.where(rut: "11.111.111-1").first
    segpres = organizations(:segpres)

    assert_equal "11.111.111-1", user.rut
    assert_equal "Perico", user.name
    assert_equal "8", user.sub
    assert_equal "ASDF", user.id_token
    assert_equal "mail@example.org", user.email
    assert_equal segpres, user.organizations.first
    assert user.can_create_schemas
    assert "Service Provider", user.roles.where(organization: segpres).first.name
  end

end
