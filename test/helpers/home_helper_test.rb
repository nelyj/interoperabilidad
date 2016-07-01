require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  include HomeHelper

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
    html_actual = dynamic_component_structure(name, spec["properties"]["nombre"], false)
    html_expected = content_tag(:div, nil, class: "panel-group") do
      content_tag(:div, nil, class: "panel panel-schema") do
        content_tag(:div, nil, class: "panel-heading clearfix") do
          content_tag(:div, nil, class: "panel-title ") do
            content_tag(:div, nil, class: "col-md-6") do
              name +
              content_tag(:p, "string", class: "data-type") +
              content_tag(:p, "Descripción descrita", class: "description")
            end +
            content_tag(:div, nil, class: "col-md-6 text-right") do
              content_tag(:a, class: "btn btn-static link-schema") do
                content_tag(:span, "schema")
              end +
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
