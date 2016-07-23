require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceOperationDetail < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:minsal),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:perico))
  end

  test "Show service operation detail" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/pets/findByStatus").click
    assert_content "Finds Pets by status"
    assert_content "Multiple status values can be provided with comma seperated strings"
  end
end
