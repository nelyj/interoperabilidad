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

  test "Show organizations ordered by the number of unavailable services" do
    ServiceVersion.delete_all
    Service.delete_all
    # SII has 2 unavailable services:
    Service.create!(
      name: "SimpleService",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end
    Service.create!(
      name: "SimpleService2",
      organization: organizations(:sii),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end

    # Segpress has 1 available service:
    Service.create!(
      name: "SimpleService3",
      organization: organizations(:segpres),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pablito)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :available)
    end

    # Minsal has 1 unavailable service:
    Service.create!(
      name: "SimpleService4",
      organization: organizations(:minsal),
      featured: true,
      public: true,
      spec_file: File.open(Rails.root / "test/files/sample-services/hello.yaml")
    ).create_first_version(users(:pedro)).tap do |version|
      version.make_current_version
      version.update_attributes!(availability_status: :unavailable)
    end

    visit root_path
    click_link "Monitoreo"
    assert_content "Institución"
    assert_content "Total Servicios"
    assert_content "Servicios no disponibles"
    assert_content "Servicios sin monitoreo"
    rows = page.all(:css, "tbody > tr")
    assert_equal 3, rows.count
    assert_includes rows[0].text, 'Servicio de Impuestos Internos'
    assert_includes rows[1].text, 'Ministerio de Salud'
    assert_includes rows[2].text, 'Secretaría General de la Presidencia'
  end
end
