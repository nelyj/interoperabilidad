require "test_helper"
require_relative 'support/ui_test_helper'

class ApproveServiceTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "GobDigital User can approve specific service version" do
    service_v = service_versions(:servicio1_v1)
    assert service_v.status == "proposed"
    login_as users(:pablito), scope: :user

    visit organization_service_service_version_path(service_v.organization, service_v.service, service_v)
    assert_button ('Aprobar')
    click_button ('Aprobar')
    assert_content 'Servicios por aprobar'
    assert ServiceVersion.where(id: service_v.id).first.status == "current"
    assert_equal 1, users(:pablito).unread_notifications
  end

  test "GobDigital User can approve a service version from list" do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('menu-pending-approval').click
    page.find(:xpath, '//table/tbody/tr[1]').click
    #find(:xpath, "//table/tr").click
    assert_button ('Aprobar')
    click_button ('Aprobar')
    assert_content 'Servicios por aprobar'
    assert ServiceVersion.where(id: service_versions(:servicio1_v1).id).first.status == "current"
    assert_equal 1, users(:pablito).unread_notifications
  end

end
