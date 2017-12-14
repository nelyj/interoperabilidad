require "test_helper"
require_relative 'support/ui_test_helper'

class MonitoringNotificationsTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Service Owner gets notified when service status is modified" do

    version = Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end

    login_as(users(:pedro))
    visit root_path
    assert_content "Catálogo de Servicios"

    within ".notifications-box" do
      assert_content 2
    end

    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Desconocido a Inactivo"

    version.update_attributes!(availability_status: :available)

    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Inactivo a Activo"
  end

  test "GobDigital User gets notified when service status is modified" do

    version = Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end

    login_as(users(:pablito))
    visit root_path
    assert_content "Catálogo de Servicios"

    within ".notifications-box" do
      assert_content 2
    end

    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Desconocido a Inactivo"

    version.update_attributes!(availability_status: :available)

    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Inactivo a Activo"
  end

  test "GobDigital user recives only ONE notification when status is modified" do

    version = Service.create!(
      name: "SimpleService",
      organization: organizations(:segpres),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pablito)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end

    login_as(users(:pablito))
    visit root_path
    assert_content "Catálogo de Servicios"


    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Desconocido a Inactivo"

    within ".notifications-box" do
      assert_content 3
    end

    version.update_attributes!(availability_status: :available)

    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')

    assert_content "El estado del servicio SimpleService cambió de Inactivo a Activo"
  end

end
