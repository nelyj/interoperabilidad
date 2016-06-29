require "test_helper"

class LoginTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "login" do
    visit root_path
    assert page.has_css?('#btn-login')
    login_as users(:perico), scope: :user
    visit root_path
    assert page.has_no_css?('#btn-login')
    assert page.has_css?('#btn-logout')
  end

end
