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

  test '.parse_organizations_and_roles new user' do
    response = Hashie::Mash.new(
    nombre: {
      apellidos: [
        "Sónico"
      ],
      nombres: [
        "Súper"
      ]
    },
    instituciones: [
      {
        "email" => "super@sonico.cl",
        institucion: {
          "id" => "AC04",
          "nombre" => "Espacio-cohetes espaciales Espacio S.A.",
          "sigla" => "ECEESA"
        },
        "rol" => "Service Provider",
      }
    ])

    new_user = User.create!(rut: "12.345.678-9", sub: "90", id_token: "ASDFGFH")
    new_user.parse_organizations_and_roles(response, nil)

    assert_equal "12.345.678-9", new_user.rut
    assert_equal "Súper Sónico", new_user.name
    assert_equal "Service Provider", new_user.roles.first.name
    assert_equal "Espacio-cohetes espaciales Espacio S.A.", new_user.organizations.first.name
    assert_equal 1, new_user.roles.length
    assert_equal 1, new_user.organizations.length
  end

  test '.parse_organizations_and_roles existing user' do
    response = Hashie::Mash.new(
    nombre: {
      apellidos: [
        "Sónico"
      ],
      nombres: [
        "Súper"
      ]
    },
    instituciones: [
      {
        "email" => "super@sonico.cl",
        institucion: {
          "id" => "AC04",
          "nombre" => "Espacio-cohetes espaciales Espacio S.A.",
          "sigla" => "ECEESA"
        },
        "rol" => "Service Provider",
      }
    ])

    new_user = User.where(rut: "44.444.444-4").first
    new_user.parse_organizations_and_roles(response, nil)

    assert_equal "44.444.444-4", new_user.rut
    assert_equal "Súper Sónico", new_user.name
    assert_equal "Service Provider", new_user.roles.first.name
    assert_equal "Espacio-cohetes espaciales Espacio S.A.", new_user.organizations.first.name
    assert_equal 1, new_user.roles.length
    assert_equal 1, new_user.organizations.length
  end

  test '.parse_organizations_and_roles delete all roles' do
    response = Hashie::Mash.new(
      RUN: {
        dv: "1",
        numero: 17022419,
        tipo: "RUN"
      },
      nombre: {
        apellidos: [
          "Fiebig"
        ],
        nombres: [
          "Alfredo"
        ]
      },
      instituciones: [
        {
          email: "juanito@dominio.cl",
          institucion: {
          id: "AB01",
          nombre: "Secretaría General de la Presidencia",
          padre_id: "AB01",
          sigla: "Segpres"
        },
        rol: "Service Provider",
      }
    ])
    user = User.where(rut: "11.111.111-1").first
    user.roles.create(organization: organizations(:sii), name: "Service Provider", email: "test@example.org")
    user.roles.create(organization: organizations(:minsal), name: "Service Provider", email: "test2@example.org")
    assert user.organizations.exists?(name: "Servicio de Impuestos Internos")
    assert user.organizations.exists?(name: "Ministerio de Salud")

    user.parse_organizations_and_roles(response, nil)

    assert user.organizations.exists?(name: "Secretaría General de la Presidencia")
    assert_not user.organizations.exists?(name: "Servicio de Impuestos Internos")
    assert_not user.organizations.exists?(name: "Ministerio de Salud")
  end

  test ".unread_notifications return the number of unread_notifications of a user" do
    user = users(:pedro)
    assert_equal 0, user.unread_notifications
    user.notifications.create(subject: Service.first, message: "", email: "")
    user.notifications.create(subject: Service.first, message: "", email: "")
    assert_equal 2, user.unread_notifications
  end

  test ".unseen_notifications return if true if the user has unseen_notifications" do
    user = users(:pedro)
    assert_not user.unseen_notifications?
    user.notifications.create(subject: Service.first, message: "", email: "")
    user.notifications.create(subject: Service.first, message: "", email: "")
    assert user.unseen_notifications?
  end

  test ".can_create_agreements? return true if the user can create agreement for the organization" do
    user = users(:pedro)
    assert user.can_create_agreements?(organizations(:sii))
  end

  test ".can_create_agreements? return false if the user can't create agreement for the organization" do
    user = users(:pedro)
    assert_not user.can_create_agreements?(organizations(:segpres))
  end

end
