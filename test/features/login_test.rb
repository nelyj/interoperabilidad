require "test_helper"

class LoginTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers

  after { Warden.test_reset! }

  def test_login
    visit root_path
    assert page.has_css?('#btn-login')
    login_as users(:perico), scope: :user
    visit root_path
    assert page.has_css?('#btn-logout')
  end

end
