require "test_helper"
require_relative 'support/ui_test_helper'

class SchemaViewSpecTest < Capybara::Rails::TestCase
  include UITestHelper

  setup do
    Schema.create!(
      name: 'VeryExternalRef',
      schema_category: schema_categories(:anotaciones),
      spec_file: File.open(Rails.root / "test/files/sample-schemas/VeryExternalRef.yaml")
    )
  end

  test "schema spec shows links for external refs" do
    visit root_path
    click_link "Esquemas"
    within(:css, ".list-categories") { find("a", text: "Anotaciones").click }
    click_link "VeryExternalRef"
    within(:schema_spec, "VeryExternalRef") do
      assert_link("schema")
      click_pointer "/properties/bufferConfiguration"
      within(:spec_pointer, "/properties/bufferConfiguration/properties/media") do
        assert_no_link("schema")
      end
      within(:spec_pointer, "/properties/bufferConfiguration/properties/services") do
        assert_no_link("schema")
      end
    end
  end
end
