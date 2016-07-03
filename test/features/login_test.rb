require "test_helper"

class LoginTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "login" do
    visit root_path
    assert_css page, '#btn-login'
    login_as users(:pedro), scope: :user
    visit root_path
    assert_no_css page, '#btn-login'
    find('#user-menu').click
    assert_css page, '#btn-logout'
  end

end
