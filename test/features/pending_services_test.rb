require "test_helper"
require_relative 'support/ui_test_helper'

class PendingServicesTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }


  test "Show PendingServices" do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find('#menu-pending-approval').click

    assert_content "Servicios por aprobar"
    rows = page.all(:xpath, '//table/tbody/tr')
    assert rows.count == 4

    assert rows[0].text.include?("servicio_1")
    assert rows[0].text.include?("R1")

    assert rows[1].text.include?("servicio_1")
    assert rows[1].text.include?("R2")

    assert rows[2].text.include?("servicio_1")
    assert rows[2].text.include?("R3")

    assert rows[3].text.include?("servicio_2")
    assert rows[3].text.include?("R1")

  end

  test "Click first of the PendingServices" do

    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find('#menu-pending-approval').click

    assert_content "Servicios por aprobar"
    rows = page.all(:xpath, '//table/tbody/tr')
    rows[0].click

    assert_content "SERVICIO PENDIENTE DE APROBACIÓN"
    assert_content "servicio_1"

  end

end
