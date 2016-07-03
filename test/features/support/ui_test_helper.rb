Capybara.add_selector(:schema_spec) do
  css {|name| ".schema-panel-set[data-name=\"#{name}\"]" }
end

Capybara.add_selector(:spec_pointer) do
  css {|pointer| "[data-pointer='#{pointer}']" }
end

module UITestHelper
  def click_pointer(pointer)
    within(:spec_pointer, pointer) do
      first('a[data-toggle=collapse-next]').trigger('click')
    end
  end

  def click_schema_category(category_name)
    within(:css, ".list-categories") { find("a", text: category_name).click }
  end
end
