require "test_helper"
require_relative 'support/ui_test_helper'

class SchemaViewSpecTest < Capybara::Rails::TestCase
  include UITestHelper

  def make_schema(name, extension)
    Schema.create!(
      name: name,
      schema_category: schema_categories(:anotaciones),
      spec_file: File.open(Rails.root / "test/files/sample-schemas/#{name}.#{extension}")
    ).create_first_version(users(:pablito))
  end


  setup do
    make_schema "VeryExternalRef", "yaml"
    make_schema "PrimitiveExternalRef", "yaml"
    make_schema "ComplexSchema", "json"
    visit root_path
    click_link "Esquemas"
    click_schema_category "Anotaciones"
  end

  test "schema spec shows links for external refs" do
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
    click_link "PrimitiveExternalRef"
    within(:schema_spec, "PrimitiveExternalRef") do
      assert_link "schema"
      assert_nil find_pointer_expand_or_collapse_link("/properties/edad")
    end
  end

  test "schema spec indicates required properties" do
    click_link "ComplexSchema"
    within(:schema_spec, "ComplexSchema") do
      assert_no_required_property "/properties/hora"
      assert_required_property "/properties/fecha"
      assert_no_required_property "/properties/nombre"
      assert_required_property "/properties/numero"
      assert_required_property "/properties/integro"
      assert_no_required_property "/properties/numero2"

      assert_no_required_property "/properties/estadosMensajes"
      click_pointer "/properties/estadosMensajes"
      click_pointer "/properties/estadosMensajes/items"
      assert_required_property "/properties/estadosMensajes/items/properties/id"
      assert_no_required_property "/properties/estadosMensajes/items/properties/tipo"
      assert_required_property "/properties/estadosMensajes/items/properties/titulo"
      assert_no_required_property "/properties/estadosMensajes/items/properties/contenido"
      assert_required_property "/properties/estadosMensajes/items/properties/tipoContenido"
      assert_no_required_property "/properties/estadosMensajes/items/properties/notificacionPorEmail"

      assert_no_required_property "/properties/estadosSiguientes"
      click_pointer "/properties/estadosSiguientes"
      click_pointer "/properties/estadosSiguientes/items"
      assert_no_required_property "/properties/estadosSiguientes/items/properties/id"
      assert_no_required_property "/properties/estadosSiguientes/items/properties/Cosas"
      click_pointer "/properties/estadosSiguientes/items/properties/Cosas"
      click_pointer "/properties/estadosSiguientes/items/properties/Cosas/items"
      assert_no_required_property "/properties/estadosSiguientes/items/properties/Cosas/items/properties/id"
      assert_no_required_property "/properties/estadosSiguientes/items/properties/nombre"
    end
  end
end
