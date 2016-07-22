Capybara.add_selector(:schema_spec) do
  css {|name| ".schema-panel-set[data-name=\"#{name}\"]" }
end

Capybara.add_selector(:spec_pointer) do
  css {|pointer| "[data-pointer='#{pointer}']" }
end

module UITestHelper
  def click_pointer(pointer)
    find_pointer_expand_or_collapse_link(pointer).trigger('click')
  end

  def find_pointer_expand_or_collapse_link(pointer)
    find(:spec_pointer, pointer).first('a[data-toggle=collapse-next]')
  end

  def click_schema_category(category_name)
    within(:css, ".list-categories") { find("a", text: category_name).click }
  end

  def assert_required_property(pointer)
    within(:spec_pointer, pointer) do
      assert_css(".panel-title.required .name")
    end
  end

  def assert_no_required_property(pointer)
    within(:spec_pointer, pointer) do
      assert_no_css(".panel-title.required .name", text: pointer.split('/').last)
    end
  end

  def find_service_row(service_name)
    find(:css, "tr[data-name=#{service_name}]")
  end
end
