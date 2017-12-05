require "test_helper"
require 'yaml'
require_relative 'support/ui_test_helper'

class TestWithMockOptionTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('services').click
    find_link('Crear Servicio').click
    fill_in 'service_name', :with => "Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "test mock option exist" do

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'hello.yaml')

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    click_button "Probar Servicio"

    select_test_with_mock_service

    assert_content 'Servicio Simulado'

    # TODO: Test Mock from here

  end

end
