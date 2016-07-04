require "test_helper"
require_relative 'support/ui_test_helper'

class SchemaViewSpecTest < Capybara::Rails::TestCase
  include UITestHelper

  setup do
    schema_1 = Schema.create!(
      name: 'VeryExternalRef',
      schema_category: schema_categories(:anotaciones),
      spec_file: File.open(Rails.root / "test/files/sample-schemas/VeryExternalRef.yaml")
    )
    schema_1.create_first_version(users(:pablito))
    schema_2 = Schema.create!(
      name: 'PrimitiveExternalRef',
      schema_category: schema_categories(:anotaciones),
      spec_file: File.open(Rails.root / "test/files/sample-schemas/PrimitiveExternalRef.yaml")
    )
    schema_2.create_first_version(users(:pablito))
  end

  test "schema spec shows links for external refs" do
    visit root_path
    click_link "Esquemas"
    click_schema_category "Anotaciones"
    click_link "VeryExternalRef"
    within(:schema_spec, "VeryExternalRef") do
      assert_link "schema"
      click_pointer "/properties/bufferConfiguration"
      within(:spec_pointer, "/properties/bufferConfiguration/properties/media") do
        assert_no_link "schema"
      end
      within(:spec_pointer, "/properties/bufferConfiguration/properties/services") do
        assert_no_link "schema"
      end
    end
  end

  test "schema spec don't show expand button for primitive external refs" do
    visit root_path
    click_link "Esquemas"
    click_schema_category "Anotaciones"
    click_link "PrimitiveExternalRef"
    within(:schema_spec, "PrimitiveExternalRef") do
      assert_link "schema"
      assert_nil find_pointer_expand_or_collapse_link("/properties/edad")
    end
  end
end
