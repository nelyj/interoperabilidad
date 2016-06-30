require "test_helper"

class SchemaSearchTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "succesful search using schema name" do
    visit schemas_path
    fill_in('search-schema', :with => "rut")
    find_by_id('search-schema').send_keys(:enter)
    assert_content page, "RUT de una persona o empresa"
  end

  test "succesful search using schema description" do
    visit schemas_path
    fill_in('search-schema', :with => "empresa")
    find_by_id('search-schema').send_keys(:enter)
    assert_content page, "RUT de una persona o empresa"
  end

  test "search results not found" do
    visit schemas_path
    fill_in('search-schema', :with => "patente")
    find_by_id('search-schema').send_keys(:enter)
    assert_content page, "No se han encontrado resultados"
  end
end
