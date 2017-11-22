require "test_helper"

class MonitorParamTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def visit_monitor_params(user)
    login_as user, scope: :user
    visit root_path
    visit monitor_params_path
    find('#user-menu').click
    assert_content page, user.name
    assert_content page, user.organizations.take.name

  end

  test 'create new monitor parameter' do
    visit_monitor_params(users(:pablito))

  end

  test 'edit monitor parameter' do
    visit_monitor_params(users(:pablito))

  end

  test 'delete monitor parameter' do
    visit_monitor_params(users(:pablito))

  end

  test 'not loged user can not create new monitor parameter' do
    visit root_path
    visit monitor_params_path
  end

  test 'not loged user can not edit monitor parameter' do
    visit root_path
    visit monitor_params_path
  end

  test 'not loged user can not delete monitor parameter' do
    visit root_path
    visit monitor_params_path
  end

  test 'non GobDigital user can not create new monitor parameter' do
    visit_monitor_params(users(:pedro))

  end

  test 'non GobDigital user can not edit monitor parameter' do
    visit_monitor_params(users(:pedro))

  end

  test 'non GobDigital user can not delete monitor parameter' do
    visit_monitor_params(users(:pedro))

  end
end
