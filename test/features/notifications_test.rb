require "test_helper"
require_relative 'support/ui_test_helper'

class NotificationsTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def make_service
    Service.create!(
      name: "petsfull",
      organization: users(:pedro).organizations.first,
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:pedro))
  end

  def make_new_version
    Service.where(name: "petsfull").first.service_versions.create(
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml"),
      user: users(:pedro),
      backwards_compatible: true)
  end

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
  end

  test "GobDigital user gets notified when a new service is created" do
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 0
    end
    make_service
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
  end

  test "GobDigital user gets notified when a new service version is created" do
    make_service
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    make_new_version
    visit root_path
    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    page.find(:xpath, '//table/tbody/tr[1]').click
    assert_content "petsfull" + ' R2'
    within ".notifications-box" do
      assert_content 0
    end
  end

  test "GobDigital user get notified of new version, then a new versions come and the old notification is mark as readed" do
    make_service
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    make_new_version
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
  end

  test "NonGobDigital user get notified of service approved" do
    make_service

    visit organization_service_service_version_path(users(:pedro).organizations.first, Service.where(name: "petsfull").first, Service.where(name: "petsfull").first.service_versions.first)
    click_button 'Aprobar'

    login_as(users(:pedro))
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    page.find(:xpath, '//table/tbody/tr[1]').click
    assert_content "petsfull" + ' R1'
    assert page.has_no_button?("Aprobar")
  end

  test "NonGobDigital user get notified of service rejected" do
    make_service

    visit organization_service_service_version_path(users(:pedro).organizations.first, Service.where(name: "petsfull").first, Service.where(name: "petsfull").first.service_versions.first)
    assert_content "petsfull" + ' R1'
    click_button 'Rechazar'

    within '.modal-body' do
      assert_content 'Ingresa la razón de rechazo'
      fill_in 'service_version_reject_message', with: "Test"
      click_button('Rechazar')
    end

    login_as(users(:pedro))
    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    click_link("Ver Notificaciones")
    assert_content "Notificaciones"
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    within ".notifications-box" do
      assert_content 1
    end
    page.find(:xpath, '//table/tbody/tr[1]').click
    assert_content "petsfull" + ' R1'
    assert page.has_no_button?("Aprobar")
  end

end
