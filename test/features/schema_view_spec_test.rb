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
    make_schema "PrimitiveSchema", "yaml"
    visit schemas_path
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

  test "schema spec lists properties and their required status" do
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

  test "schema spec lists constraints and data types" do
    click_link "ComplexSchema"
    within(:schema_spec, "ComplexSchema") do
      within :spec_pointer, "/properties/hora" do
        assert_content "string"
        assert_content "/[0-9] {1}/"
      end
      within :spec_pointer, "/properties/fecha" do
        assert_content "string"
        assert_content "date-time"
      end
      within :spec_pointer, "/properties/nombre" do
        assert_content "string"
        assert_content "enum"
        assert_content "pepe"
        assert_content "juan"
      end
      within :spec_pointer, "/properties/numero" do
        assert_content "number"
        assert_content "múltiplo de 5"
        assert_content "3 ≤ x ≤ 7"
      end
      within :spec_pointer, "/properties/integro" do
        assert_content "integer"
        assert_content "default 5"
        assert_content "3 < x < 7"
      end
      within :spec_pointer, "/properties/numero2" do
        assert_content "number"
        assert_content "x ≥ 3"
      end
      within :spec_pointer, "/properties/estadosMensajes" do
        assert_content "array"
        assert_content "elementos únicos"
        assert_content "mínimo 2 elementos"
      end
      click_pointer "/properties/estadosMensajes"
      within :spec_pointer, "/properties/estadosMensajes/items" do
        assert_content "object"
      end
      click_pointer "/properties/estadosMensajes/items"
      within :spec_pointer, "/properties/estadosMensajes/items/properties/id" do
        assert_content "number"
      end
      within :spec_pointer, "/properties/estadosMensajes/items/properties/tipo" do
        assert_content "string"
      end
      within :spec_pointer, "/properties/estadosMensajes/items/properties/titulo" do
        assert_content "string"
      end
      within :spec_pointer, "/properties/estadosMensajes/items/properties/contenido" do
        assert_content "string"
      end
      within :spec_pointer, "/properties/estadosMensajes/items/properties/tipoContenido" do
        assert_content "string"
        assert_content "enum:"
        assert_content "TXT"
        assert_content "HTML"
        assert_content "PDF"
        assert_content "NADA"
      end
      within :spec_pointer, "/properties/estadosMensajes/items/properties/notificacionPorEmail" do
        assert_content "boolean"
      end
      within :spec_pointer, "/properties/estadosSiguientes" do
        assert_content "array"
        assert_content "mínimo 1 elemento"
      end
      click_pointer "/properties/estadosSiguientes"
      within :spec_pointer, "/properties/estadosSiguientes/items" do
        assert_content "object"
      end
      click_pointer "/properties/estadosSiguientes/items"
      within :spec_pointer, "/properties/estadosSiguientes/items/properties/id" do
        assert_content "string"
      end
      within :spec_pointer, "/properties/estadosSiguientes/items/properties/Cosas" do
        assert_content "array"
      end
      click_pointer "/properties/estadosSiguientes/items/properties/Cosas"
      within :spec_pointer, "/properties/estadosSiguientes/items/properties/Cosas/items" do
        assert_content "object"
      end
      click_pointer "/properties/estadosSiguientes/items/properties/Cosas/items"
      within :spec_pointer, "/properties/estadosSiguientes/items/properties/Cosas/items/properties/id" do
        assert_content "string"
      end
      within :spec_pointer, "/properties/estadosSiguientes/items/properties/nombre" do
        assert_content "string"
      end
    end
  end

  test "primitive schemas do not render an 'empty' name" do
    click_link "PrimitiveSchema"
    within(:schema_spec, "PrimitiveSchema") do
      assert_no_css(".name") # It is present in the DOM, but invisible
    end
  end
end
