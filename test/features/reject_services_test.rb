require "test_helper"
require_relative 'support/ui_test_helper'

class RejectServiceTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "GobDigital User can reject specific service version" do
    service_v = service_versions(:servicio1_v3)
    assert service_v.status == "proposed"
    login_as users(:pablito), scope: :user
    visit organization_service_service_version_path(service_v.organization, service_v.service, service_v)
    assert_button ('Rechazar')
    click_button ('Rechazar')
    within '.modal-body' do
      assert_content 'Ingresa la razón de rechazo'
      click_button('Rechazar')
    end
    assert ServiceVersion.where(id: service_v.id).first.status == "rejected"
    assert_equal 1, users(:pablito).unread_notifications
  end

  test "GobDigital User can reject a service version from list" do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('menu-pending-approval').click
    page.find(:xpath, '//table/tbody/tr[1]').click
    assert_button ('Rechazar')
    click_button ('Rechazar')
    assert_content 'Rechazar Servicio'
    within '.modal-body' do
      assert_content 'Ingresa la razón de rechazo'
      click_button('Rechazar')
    end
    assert ServiceVersion.where(id: service_versions(:servicio1_v1).id).first.status == "rejected"
    assert_equal 1, users(:pablito).unread_notifications
  end

end
