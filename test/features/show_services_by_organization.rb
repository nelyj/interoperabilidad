require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceByOrganization < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    Service.create!(
      name: "FichaMedica",
      organization: organizations(:minsal),
      featured: true,
      public: false,
      spec_file: File.open(Rails.root / "test/files/sample-services/echo.yaml")
    ).create_first_version(users(:perico))
  end

  test "Show organization services after clicking on organization name" do
    visit root_path
    assert_content "FichaMedica"
    click_link "Ministerio de Salud"
    assert_content "servicio_2"
    assert_content "FichaMedica"
    assert_equal 'Ministerio de Salud', find('#search-service').value
  end
end
