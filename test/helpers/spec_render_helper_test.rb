require 'test_helper'

class SpecRenderHelperTest < ActionView::TestCase
  include SpecRenderHelper
  include ApplicationHelper

  test "#json_pointer_path" do
    assert_equal "/", json_pointer_path('/')
    assert_equal "/foo/bar", json_pointer_path('/foo', 'bar')
    assert_equal "/foo/bar/baz", json_pointer_path('/foo', 'bar', 'baz')
    assert_equal "/foo/bar~0/baz", json_pointer_path('/foo', 'bar~', 'baz')
    assert_equal "/foo/bar~1baz/qux", json_pointer_path('/foo', 'bar/baz', 'qux')
  end

  test "#schema_link_if_reference_present renders the link when a remote reference is present" do
    uri = "http://external.com/ref"
    references = {
      "#/foo/bar/baz" => {
        'type' => 'remote',
        'uri' => uri
      }
    }
    expected = content_tag(:a, class: "btn btn-static link-schema", href: uri, rel: "noopener noreferrer", target: "_blank") do
      content_tag(:span, "schema")
    end
    assert_equal expected,
      schema_link_if_reference_present('/foo/bar/baz', references)
  end

  test "#schema_link_if_reference_present does not render the link when a local reference is present" do
    uri = "#/local/ref"
    references = {
      "#/foo/bar/baz" => {
        'type' => 'local',
        'uri' => uri
      }
    }
    expected = ""
    assert_equal expected,
      schema_link_if_reference_present('/foo/bar/baz', references)
  end

  test "#schema_link_if_reference_present does not render the link when no reference is present" do
    references = {
      "#/foo/bar/baz" => {
        'type' => 'local',
        'uri' => "foo"
      }
    }
    expected = ""
    assert_equal expected,
      schema_link_if_reference_present('/foo/bar/qux', references)
  end

  test "#looks_like_standard_schema_uri? returns true for schema version urls like ours" do
    assert looks_like_standard_schema_uri? 'http://interoperabilidad.digital.gob.cl/schemas/foo/versions/4'
    assert looks_like_standard_schema_uri? 'https://interoperabilidad.digital.gob.cl/schemas/foo/versions/4.json'
    assert looks_like_standard_schema_uri? 'https://we.dont.really.care.about.the.host/schemas/Foo%Bar/versions/4534543535435435543'
  end

  test "#looks_like_standard_schema_uri? returns false for other urls" do
    assert !looks_like_standard_schema_uri?('http://interoperabilidad.digital.gob.cl/schemas/foo.json')
    assert !looks_like_standard_schema_uri?('https://raw.githubusercontent.com/e-gob/interoperabilidad/e55458eb64cb8e561d365e88064ccf2db25fc48f/test/files/sample-schemas/VeryExternalRef.yaml')
  end

  test "#markup_humanizer returns a human readable range" do
    assert_equal "<li>rango 7-11 elementos</li>", markup_humanizer('elemento', 's', max: 11, min: 7)
    assert_equal "<li>rango 0-1 elemento</li>", markup_humanizer('elemento', 's', max: 1, min: 0)
  end

  test "#markup_humanizer returns a human readable length" do
    assert_equal "<li>largo 7 elementos</li>", markup_humanizer('elemento', 's', max: 7, min: 7)
    assert_equal "<li>largo 1 elemento</li>", markup_humanizer('elemento', 's', max: 1, min: 1)
  end

  test "#markup_humanizer returns the maximum value" do
    assert_equal "<li>máximo 20 elementos</li>", markup_humanizer('elemento', 's', max: 20)
    assert_equal "<li>máximo 1 item</li>", markup_humanizer('item', 's', max: 1)
  end

  test "#markup_humanizer returns the minimum value" do
    assert_equal "<li>mínimo 3 items</li>", markup_humanizer('item', 's', min: 3)
    assert_equal "<li>mínimo 1 elemento</li>", markup_humanizer('elemento', 's', min: 1)
  end

  test "#markup_humanizer returns an empty string when max and min are not present" do
    assert_equal "".html_safe, markup_humanizer('elemento', 's')
  end

  test "#schema_markup redirects array to properly submethods" do
    schema_version = schema_versions(:arreglin_v3)
    name = schema_version.schema.name
    spec = schema_version.spec_with_resolved_refs['definition']
    references = schema_version.spec_with_resolved_refs['references']
    html = content_tag(:div, class: "schema-panel-set detail", data: {name: name, version: schema_version.version_number}) do
      content_tag(:h3, schema_version.schema.name) +
      schema_object_property_markup('', spec, false, '/', references)
    end
    assert_equal html, schema_markup(schema_version)
  end

  test "#schema_markup redirects object to properly submethods" do
    schema_version = schema_versions(:rut_v1)
    name = schema_version.schema.name
    spec = schema_version.spec_with_resolved_refs['definition']
    references = schema_version.spec_with_resolved_refs['references']
    html = content_tag(:div, class: "schema-panel-set detail", data: {name: name, version: schema_version.version_number}) do
      content_tag(:h3, schema_version.schema.name) +
      schema_object_spec_markup(spec, '/', references)
    end
    assert_equal html, schema_markup(schema_version)
  end

  test "#schema_markup redirects primitive to properly submethods" do
    schema_version = schema_versions(:fecha_iso_v1)
    name = schema_version.schema.name
    spec = schema_version.spec_with_resolved_refs['definition']
    references = schema_version.spec_with_resolved_refs['references']
    html = content_tag(:div, class: "schema-panel-set detail", data: {name: name, version: schema_version.version_number}) do
      content_tag(:h3, schema_version.schema.name) +
      schema_object_property_markup('', spec, false, '/', references)
    end
    assert_equal html, schema_markup(schema_version)
  end

  test "#schema_object_property_markup redirects to properly submethods" do
    property_definition = schema_versions(:complex_v1).spec["properties"]["nombre"]
    html = schema_object_primitive_property_markup(
      "nombre", property_definition, true, '', ''
    )
    assert_equal html, schema_object_property_markup(
      "nombre", property_definition, true, '', ''
    )
    property_definition = schema_versions(:complex_v1).spec["properties"]["rut"]
    html = schema_object_complex_property_markup(
      "rut", property_definition, true, '', ''
    )
    assert_equal html, schema_object_property_markup(
      "rut", property_definition, true, '', ''
    )
    property_definition = schema_versions(:complex_v1).spec["properties"]["estadosMensajes"]
    html = schema_object_array_property_markup(
      "estadosMensajes", property_definition, true, '', ''
    )
    assert_equal html, schema_object_property_markup(
      "estadosMensajes", property_definition, true, '', ''
    )
  end

  test "#schema_object_complex_property_markup represents an object" do
    property_definition = schema_versions(:complex_v1).spec["properties"]["rut"]
    name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, "rut", class: "name")
    end
    html = dynamic_component_structure(name_markup, property_definition, true, '', '') do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_spec_markup(property_definition, '', '')
      end
    end
    assert_equal html, schema_object_complex_property_markup(
        "rut", property_definition, true, '', ''
      )
  end

  test "#schema_object_array_property_markup represents an array" do
    property_definition = schema_versions(:complex_v1).spec["properties"]["estadosMensajes"]
    name_markup = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, "estadosMensajes", class: "name")
    end
    html = dynamic_component_structure(
      name_markup, property_definition, true, '', ''
    ) do
      content_tag(:div, nil, class: "panel-body") do
        schema_object_property_markup(
          "(elementos)".html_safe, property_definition["items"], false,
          json_pointer_path('', "items"), ''
        )
      end
    end
    assert_equal html, schema_object_array_property_markup(
        "estadosMensajes", property_definition, true, '', ''
      )
  end

  test "#schema_object_primitive_property_markup represents a primitive" do
    property_definition = schema_versions(:complex_v1).spec["properties"]["nombre"]
    name_markup = content_tag(:span, "nombre", class: "name")
    html = dynamic_component_structure(
      name_markup, property_definition, true,
      '', ''
    )
    assert_equal html, schema_object_primitive_property_markup(
        "nombre", property_definition, true, '', ''
      )
  end

  test "#schema_object_specific_markup returns html to represent a string primitive" do
    spec = schema_versions(:complex_v1).spec
    html = schema_object_specific_markup(spec["properties"]["hora"])
    assert_equal "<li class=\"reg-exp\"><span>/[0-9] {2}/</span></li>", html
  end

  test "#schema_object_specific_markup represents a number primitive" do
    spec = schema_versions(:complex_v1).spec
    assert_equal numeric_primitive_markup(spec["properties"]["numero"]),
      schema_object_specific_markup(spec["properties"]["numero"])
  end

  test "#schema_object_specific_markup represents a integer primitive" do
    spec = schema_versions(:complex_v1).spec
    assert_equal numeric_primitive_markup(spec["properties"]["integro"]),
      schema_object_specific_markup(spec["properties"]["integro"])
  end

  test "#schema_object_specific_markup represents a string primitive" do
    spec = schema_versions(:complex_v1).spec
    assert_equal string_primitive_markup(spec["properties"]["nombre"]),
      schema_object_specific_markup(spec["properties"]["nombre"])
  end

  test "#schema_object_specific_markup represents an array" do
    spec = schema_versions(:complex_v1).spec
    assert_equal array_specific_markup(spec["properties"]["estadosMensajes"]),
      schema_object_specific_markup(spec["properties"]["estadosMensajes"])
  end

  test "#schema_object_specific_markup represents an object" do
    spec = schema_versions(:complex_v1).spec
    assert_equal object_specific_markup(spec["properties"]["rut"]),
      schema_object_specific_markup(spec["properties"]["rut"])
  end

  test "#object_specific_markup represents markup for objects" do
    spec = schema_versions(:complex_v1).spec
    html = schema_object_specific_markup(spec["properties"]["rut"])
    assert_equal markup_humanizer("propiedad", "es", max: 3), html
  end

  test "#schema_object_common_markup returns html to represent an enum" do
    spec = schema_versions(:complex_v1).spec
    html = schema_object_common_markup(spec["properties"]["nombre"])
    assert_equal "<li>enum: pepe<br>juan<br></li>", html
  end

  test "#schema_object_common_markup returns html to represent the default value" do
    spec = schema_versions(:complex_v1).spec
    html = schema_object_common_markup_default(spec["properties"]["numero"])
    assert_equal content_tag(:li, 'default 5'), html
  end

  test "#numeric_primitive_markup returns html to represent a numeric property" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup(spec["properties"]["integro"])
    html_expected = content_tag(:li, "múltiplo de 5") + content_tag(:li, "4 < x < 16")
    assert_equal html_expected, html_actual
  end

  test "#numeric_primitive_markup represents exclusive bounds when max and min are present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["integro"])
    assert_equal content_tag(:li, "4 < x < 16"), html_actual
  end

  test "#numeric_primitive_markup represents bounds when max and min are present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["numero"])
    assert_equal content_tag(:li, "3 ≤ x ≤ 7"), html_actual
  end

  test "#numeric_primitive_markup represents bounds when min is present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["numero2"])
    assert_equal content_tag(:li, "x ≥ 3"), html_actual
  end

  test "#numeric_primitive_markup represents exclusive bounds when max is present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["integro2"])
    assert_equal content_tag(:li, "x < 7"), html_actual
  end

  test "#numeric_primitive_markup represents exclusive bounds when min is present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["numero3"])
    assert_equal content_tag(:li, "x > 5"), html_actual
  end

  test "#numeric_primitive_markup represents bounds when max is present" do
    spec = schema_versions(:complex_v1).spec
    html_actual = numeric_primitive_markup_bounds(spec["properties"]["integro3"])
    assert_equal content_tag(:li, "x ≤ 4"), html_actual
  end

  test "#array_specific_markup represents of an array property" do
    spec = schema_versions(:complex_v1).spec
    assert_equal content_tag(:li, "mínimo 1 elemento"),
      array_specific_markup(spec["properties"]["estadosSiguientes"])
  end

  test "#array_specific_markup represents an array property with unique items" do
    spec = schema_versions(:complex_v1).spec
    assert_equal content_tag(:li, "elementos únicos") + content_tag(:li, "mínimo 2 elementos"),
      array_specific_markup(spec["properties"]["estadosMensajes"])
  end

  test "#dynamic_component_structure returns html base structure to represent a property" do
    spec = schema_versions(:complex_v1).spec
    name = content_tag(:a, nil, data: {toggle: "collapse-next"}) do
      content_tag(:span, "test", class: "name")
    end
    html_actual = dynamic_component_structure(name, spec["properties"]["nombre"], false, '/properties/nombre', {})
    html_expected = content_tag(:div, nil, class: "panel-group", data: {pointer: '/properties/nombre'}) do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title ") do
            content_tag(:div, nil, class: "col-md-6") do
              name +
              content_tag(:p, "string", class: "data-type") +
              content_tag(:div, class: "description") do
                markdown.render("Descripción descrita").html_safe
              end
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:ul) do
                content_tag(:li, "enum: pepe<br>juan<br>".html_safe)
              end
            end
          end
        end +
        content_tag(:div, nil, class: "panel-collapse collapse")
      end
    end
    assert_equal html_expected, html_actual
  end
end
