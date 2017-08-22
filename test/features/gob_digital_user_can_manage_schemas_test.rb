require "test_helper"
require_relative 'support/ui_test_helper'

class GobDigitalUserCanManageSchemasTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "Loged User can_create_schema can see Nuevo Esquema button " do
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
    visit schemas_path
    assert_text 'Catálogo de Esquemas'
    click_schema_category 'Zonas'
    assert_text 'Zona Norte'
    click_link 'Zona Norte'

    within ".container-schema-detail" do
      assert_selector 'h1', text: 'Zona Norte'
    end
    assert_no_link "Nueva Versión"

    login_as users(:pablito), scope: :user
    visit schemas_path
    assert_text 'Catálogo de Esquemas'
    click_schema_category "Zonas"
    assert_text 'Zona Norte'
    click_link 'Zona Norte'

    within ".container-schema-detail" do
      assert_selector 'h1', text: 'Zona Norte'
    end
    assert_link "Nueva Revisión"
  end

end
