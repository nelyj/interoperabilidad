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
end
