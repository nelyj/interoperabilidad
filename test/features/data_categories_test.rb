require "test_helper"
require_relative 'support/ui_test_helper'

class DataCategoriesTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('menu-data-categories').click
  end

  test "Attempt to create a data category" do
    click_on 'Crear categoría'
    fill_in "data_category_name", with: 'look_at_me_im_a_category'
    click_on 'Enviar datos'
    assert_content 'Registro creado'
    category = DataCategory.find_by(name: 'look_at_me_im_a_category')
    assert category
  end


  test "Attempt to edit a data category" do
    find_all('a', text: 'Editar').first.click
    name = find("#data_category_name").value
    category_id = DataCategory.find_by(name: name).id
    fill_in 'Nombre', with: "a random name"
    click_on 'Enviar datos'

    assert_equal DataCategory.find(category_id).name, 'a random name'
  end

  test "Attempt to delete a data category" do
    assert_difference 'DataCategory.count', -1 do
      find_all('a', text: 'Eliminar').first.click
      assert_content 'Borrado exitosamente'
    end
  end

  test "Should redirect to services path when not logged in" do
    visit root_path
    find('#user-menu').click
    find_link('btn-logout').click
    visit data_categories_path
    assert_equal services_path, current_path
  end
end