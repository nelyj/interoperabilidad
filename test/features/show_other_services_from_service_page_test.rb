require "test_helper"
require_relative 'support/ui_test_helper'

class ShowOtherServicesFromServicePageTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:perico))
    @another_service_v = Service.create!(
      name: "EchoService",
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/echo.yaml")
    ).create_first_version(users(:perico))
  end

  test "Switch to another service of the same organization" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    select 'EchoService', from: 'switch_service_select'
    assert_content "Echos back every URL, method, parameter and header"
  end
end
