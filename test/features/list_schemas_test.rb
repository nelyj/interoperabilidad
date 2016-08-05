require "test_helper"
require_relative 'support/ui_test_helper'

class ListSchemasTest < Capybara::Rails::TestCase
  include UITestHelper

  test "Schema#Index list all schemas on first category" do
    visit schemas_path
    within ".list-categories" do
      assert_selector 'li', text: schema_categories(:anotaciones).name
    end
    assert_content page, "AnotacionesSchema1"
    assert_content page, "AnotacionesSchema2"
    assert_content page, "AnotacionesSchema3"
  end

  test "Schema#Index list all categories" do
    visit schemas_path
    within ".list-categories" do
      assert_selector 'li', text: schema_categories(:anotaciones).name
      assert_selector 'li', text: schema_categories(:formatos_de_fechas_y_horas).name
      assert_selector 'li', text: schema_categories(:informacion_de_personas).name
    end
  end

  test "Schema#Index list all schemas in specific category" do
    visit schemas_path
    click_schema_category "Zonas"
    assert_selector 'li.active', text: schema_categories(:zonas).name
    assert_content page, "Zona Norte"
    assert_content page, "Zona Centro"
    assert_content page, "Zona Sur"
    assert_content page, "Zona Costera"
  end
end
