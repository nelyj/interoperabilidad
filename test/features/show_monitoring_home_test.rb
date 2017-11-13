require "test_helper"
require_relative 'support/ui_test_helper'

class ShowMonitoringHomeTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Show organization with services right after they are uploaded " do
    visit root_path
    click_link "Monitoreo"
    assert_content "Institución"
    assert_content "Total Servicios"
    assert_content "Servicios no disponibles"
    assert_content "Servicios sin monitoreo"
    assert_no_content "Servicio de Impuestos Internos" # no services => no monitoring

    Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro))
    # Now we *do* have a service for SII, so it should appear on the monitoring section:
    visit root_path
    click_link "Monitoreo"
    assert_content "Institución"
    assert_content "Total Servicios"
    assert_content "Servicios no disponibles"
    assert_content "Servicios sin monitoreo"
    assert_match(
      /Servicio de Impuestos Internos 1 0 1/,
      page.first(:css, "tr[data-organization-id='#{organizations(:sii).id}']").text
    )
  end
end
