require "test_helper"
require_relative 'support/ui_test_helper'

class ShowMonitoringOrganizationDetailTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before :each do
    service = Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    )
    service.create_first_version(users(:pedro))
  end

  test "Show organization's services right after they are uploaded " do
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
    assert_match(
      /Secretaría General de la Presidencia 1 0 1/,
      page.first(:css, "tr[data-organization-id='#{organizations(:segpres).id}']").text
    )
    click_link "Servicio de Impuestos Internos"
    assert_content "SimpleService"
  end

  test "Filter/search on the table with" do
    visit root_path
    click_link "Monitoreo"
    find('[placeholder="Buscar por nombre"]').set('general')
    assert_content 'Secretaría General de la Presidencia'
    assert_no_content 'Servicio de Impuestos Internos'
    find('[placeholder="Buscar por nombre"]').set('IMPUESTOS')
    assert_content 'Servicio de Impuestos Internos'
    assert_no_content 'Secretaría General de la Presidencia'
  end
end
