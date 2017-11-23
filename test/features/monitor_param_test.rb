require "test_helper"
require_relative 'support/ui_test_helper'

class MonitorParamTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def visit_monitor_params(user)
    login_as user, scope: :user
    visit root_path

    find('#user-menu').click
    assert_content page, user.name
    assert_content page, user.organizations.take.name

    find_link('Parámetros de Monitoreo').click
    assert find(:xpath, '//table/tbody/tr[1]').text.include?("Secretaría General de la Presidencia 1 5 Eliminar")
  end

  test 'cant create duplicated monitor parameter' do
    visit_monitor_params(users(:pablito))
    assert_content 'Parámetros de Monitoreo'

    find_link('Nuevo parámetro de monitoreo').click
    assert_content 'Nuevo parámetro de monitoreo'

    find('#save-parameter').click
    page.must_have_content('No se pudo guardar el parámetro debido a 1 error Organización ya está en uso')
  end

  test 'create new monitor parameter' do
    visit_monitor_params(users(:pablito))
    assert_content 'Parámetros de Monitoreo'

    find_link('Nuevo parámetro de monitoreo').click
    assert_content 'Nuevo parámetro de monitoreo'

    find("#monitor_param_organization_id").find(:xpath, 'option[2]').select_option
    fill_in 'monitor_param_health_check_frequency', :with => "7"
    fill_in 'monitor_param_unavailable_threshold', :with => "8"

    find('#save-parameter').click

    assert_content page, 'Nuevo parametro de monitoreo creado correctamente.'

    assert find(:xpath, '//table/tbody/tr[last()]').text.include?("Servicio de Impuestos Internos 7 8 Eliminar")

  end

  test 'edit monitor parameter' do
    visit_monitor_params(users(:pablito))
    assert_content 'Parámetros de Monitoreo'

    find(:xpath, '//table/tbody/tr[1]').click

    assert_content page, 'Editar parámetro de monitoreo'
    fill_in 'monitor_param_health_check_frequency', :with => "13"
    fill_in 'monitor_param_unavailable_threshold', :with => "13"

    find('#save-parameter').click

    assert_content page, 'Parametro de monitoreo actualizado correctamente.'
    assert find(:xpath, '//table/tbody/tr[last()]').text.include?("Secretaría General de la Presidencia 13 13 Eliminar")

  end

  test 'delete monitor parameter' do
    visit_monitor_params(users(:pablito))
    assert_content 'Parámetros de Monitoreo'
    find(:xpath, '//table/tbody/tr[1]/td[last()]').click

    assert_content page, 'Parametro de monitoreo eliminado correctamente.'
    assert find(:xpath, '//table/tbody/tr[last()]').text.include?("Ministerio de Salud 1 5 Eliminar")

  end

  test 'not loged user can not create new monitor parameter' do
    visit root_path
    visit new_monitor_param_path

    assert_content page, 'Para administrar los parámetros de monitoreo por favor identifíquese con su clave única'
  end

  test 'not loged user can not edit monitor parameter' do
    visit root_path
    visit edit_monitor_param_path(monitor_params(:one))

    assert_content page, 'Para administrar los parámetros de monitoreo por favor identifíquese con su clave única'
  end

  test 'non GobDigital user can not create new monitor parameter' do
    login_as users(:pedro), scope: :user
    visit root_path
    visit new_monitor_param_path

    assert_content page, 'No tiene permisos para editar estos parámetros'
  end

  test 'non GobDigital user can not edit monitor parameter' do
    login_as users(:pedro), scope: :user
    visit root_path
    visit edit_monitor_param_path(monitor_params(:one))

    assert_content page, 'No tiene permisos para editar estos parámetros'
  end
end
