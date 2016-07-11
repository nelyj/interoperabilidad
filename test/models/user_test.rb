require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test '#refresh_user_roles_and_email! login of user without roles' do
    user = users(:perico)
    segpres = organizations(:segpres)
    auth = Hashie::Mash.new(
      extra: {raw_info: {"RUT" => "22.222.222-2", "sub" => "8", "nombres" => "Perico", "apellidoPaterno" => "de los", "apellidoMaterno" => "Palotes"}},
      credentials: {id_token: "ASDF"}
    )
    user.refresh_user_roles_and_email(auth.extra.raw_info)
    assert user.roles.empty?
    assert user.organizations.empty?
    assert !user.can_create_schemas
  end

  test '.from_omniauth sets Auth params to new user' do
    auth = Hashie::Mash.new(
      extra: {raw_info: {"RUT" => "55.555.555-5", "sub" => "8", "nombres" => "Perico", "apellidoPaterno" => "de los", "apellidoMaterno" => "Palotes"}},
      credentials: {id_token: "ASDF"}
    )
    User.from_omniauth(auth)
    user = User.where(rut: "55.555.555-5").first

    assert_equal "55.555.555-5", user.rut
    assert_equal "Perico de los Palotes", user.name
    assert_equal "8", user.sub
    assert_equal "ASDF", user.id_token
    assert user.roles.empty?
    assert user.organizations.empty?
    assert !user.can_create_schemas
  end

  test '.from_omniauth sets Auth params to existing user' do
    auth = Hashie::Mash.new(
      extra: {raw_info: {"RUT" => "11.111.111-1", "sub" => "8", "nombres" => "Perico", "apellidoPaterno" => "de los", "apellidoMaterno" => "Palotes"}},
      credentials: {id_token: "ASDF"}
    )
    user = User.where(rut: "11.111.111-1").first
    assert_equal "11.111.111-1", user.rut
    assert_equal "2", user.sub
    assert_equal "some-token", user.id_token

    User.from_omniauth(auth)

    user = User.where(rut: "11.111.111-1").first

    assert_equal "11.111.111-1", user.rut
    assert_equal "Perico de los Palotes", user.name
    assert_equal "8", user.sub
    assert_equal "ASDF", user.id_token
    assert user.roles.empty?
    assert user.organizations.empty?
    assert !user.can_create_schemas
  end
end
