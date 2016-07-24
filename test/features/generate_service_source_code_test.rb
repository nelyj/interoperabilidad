require "test_helper"
require_relative 'support/ui_test_helper'

class GenerateServiceSourceCodeTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }


  test "Generate source code for a service" do
    service_v = service_versions(:servicio1_v3)
    visit organization_service_service_version_path(
      service_v.organization, service_v.service, service_v
    )
    click_button "Generar código fuente"
    within(:css, '#modalDownloadCode') do
      assert_content "Descarga Cliente"
      assert_content "Descarga Servidor"
      check "JAVA"
      check "PHP: SLIM"
      click_link "Generar código fuente"
    end
    # No idea on how to check for the generated zip file
  end
end
