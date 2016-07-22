require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceHome < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Show only featured services on the initial home page" do
    visit root_path
    assert_content "servicio_1"
    assert_no_content "servicio_2"
  end
end
