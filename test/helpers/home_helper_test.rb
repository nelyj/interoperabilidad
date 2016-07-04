require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  include HomeHelper

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
    assert_equal "<li>rango 7-11 elementos</li>", markup_humanizer('elemento', 's', 11, 7)
  end

  test "#markup_humanizer returns a human readable length" do
    assert_equal "<li>largo 7 elementos</li>", markup_humanizer('elemento', 's', 7, 7)
  end

  test "#schema_object_specific_markup returns html to represent a string primitive" do
    spec = schema_versions(:complex_v1).spec
    html = content_tag(:ul) do
      schema_object_specific_markup(spec["properties"]["hora"])
    end
    assert_equal "<ul><li class=\"reg-exp\"><span>/[0-9] {2}/</span></li></ul>", html
  end

  test "#schema_object_common_markup returns html to represent an enum" do
    spec = schema_versions(:complex_v1).spec
    html = content_tag(:ul) do
      schema_object_common_markup(spec["properties"]["nombre"])
    end
    assert_equal "<ul><li>enum: pepe<br>juan<br></li></ul>", html
  end

  test "#numeric_primitive_markup returns html to represent a numeric property" do
    spec = schema_versions(:complex_v1).spec
    html_actual = content_tag(:ul) do
      numeric_primitive_markup(spec["properties"]["integro"])
    end
    html_expected = content_tag(:ul) do
      content_tag(:li, "múltiplo de 5") +
      content_tag(:li, "4 < x < 16")
    end
    assert_equal html_expected, html_actual
  end

  test "#array_specific_markup returns html to represent a numeric property" do
    spec = schema_versions(:complex_v1).spec
    html_actual = content_tag(:ul) do
      array_specific_markup(spec["properties"]["estadosMensajes"])
    end
    html_expected = content_tag(:ul) do
      content_tag(:li, "elementos únicos") +
      content_tag(:li, "mínimo 2 elementos")
    end
    assert_equal html_expected, html_actual
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
