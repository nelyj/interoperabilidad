require "test_helper"
require_relative 'support/ui_test_helper'

class GobDigitalUserCanManageSchemasTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Loged User can_create_schema can see Nuevo Esquema button " do
    visit root_path
    login_as users(:pedro), scope: :user
    visit root_path
    find('#user-menu').click
    assert_no_link 'menu-new-schema'

    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    assert_link 'menu-new-schema'
  end

  test "Loged User can_create_schema can see Nueva Version button" do
    visit root_path
    click_link 'Esquemas'
    assert_text 'Directorio de Esquemas'
    click_schema_category schema_categories(:zonas).name
    click_link schemas(:zona1).name

    within ".container-schema-detail" do
      assert_selector 'h1', text: schemas(:zona1).name
    end
    assert_no_link "Nueva Versión"

    login_as users(:pablito), scope: :user
    visit root_path
    click_link 'Esquemas'
    assert_text 'Directorio de Esquemas'
    click_schema_category schema_categories(:zonas).name
    assert_text schemas(:zona1).name
    click_link schemas(:zona1).name

    within ".container-schema-detail" do
      assert_selector 'h1', text: schemas(:zona1).name
    end
    assert_link "Nueva Versión"
  end

end
