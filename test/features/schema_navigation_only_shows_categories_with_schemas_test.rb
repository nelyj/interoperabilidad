require "test_helper"

class SchemaNavigationOnlyShowsCategoriesWithSchemasTest < Capybara::Rails::TestCase
  test "don't show categories without schemas" do
    visit schemas_path
    assert_content "Zonas"
    assert_no_content "CategoriaSinNingunEsquema"
  end
end
