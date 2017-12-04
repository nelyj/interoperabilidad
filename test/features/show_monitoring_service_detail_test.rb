require "test_helper"
require_relative 'support/ui_test_helper'

class ShowMonitoringServiceDetailTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Show organization's services right after they are uploaded " do
    service = Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    )
    service.create_first_version(users(:pedro))
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
    click_link "Servicio de Impuestos Internos"
    click_link "SimpleService"
    assert_content "Fecha / Hora de Monitoreo"
  end
end
