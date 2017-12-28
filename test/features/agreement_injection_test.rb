require "test_helper"
require_relative 'support/agreement_creation_helper'

class AgreementInjectionTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test 'not loged user can not inject new Agreement Global' do
    visit agreements_new_injection_path
    assert_content('Para revisar los convenios de la plataforma por favor identifíquese con su clave única')
  end

  test 'non GobDigital User can not inject new Agreement' do
    login_as users(:pedro), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      assert has_no_field?('#menu-vista-global-convenios')
    end

    visit agreements_new_injection_path
    assert_content('No tiene permisos suficientes')

  end

  test 'GobDigital User can not inject new Agreement with same Organization' do
    login_as users(:pablito), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      find('#menu-vista-global-convenios').click
    end

    assert_content('Vista Global de Convenios')
    find_link('Subir un convenio existente').click

    assert_content('Crear Nuevo Convenio')

    page.execute_script('$("input[type=file]").show()')
    attach_file '_agreements_global_file', Rails.root.join('test/files/sample-pdf/content.pdf')

    find("#select2-_agreements_global_service_consumer_organization_id-container").click
    find_all(".select2-results__option")[1].click

    find("#select2-agreement_service_provider_organization_id-container").click
    find_all(".select2-results__option")[1].click

    click_button 'Crear Nuevo Convenio'

    assert_content("No se pudo crear el convenio")
    assert_content("Las organizaciones deben ser distintas")
  end

  test 'GobDigital User can not inject new Agreement without a PDF' do
    login_as users(:pablito), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      find('#menu-vista-global-convenios').click
    end

    assert_content('Vista Global de Convenios')
    find_link('Subir un convenio existente').click

    assert_content('Crear Nuevo Convenio')

    find("#select2-_agreements_global_service_consumer_organization_id-container").click
    find_all(".select2-results__option")[1].click

    find("#select2-agreement_service_provider_organization_id-container").click
    find_all(".select2-results__option")[2].click

    click_button 'Crear Nuevo Convenio'

    assert_content("No se pudo guardar el convenio")
    assert_content("El archivo debe ser un pdf")
  end

  test 'GobDigital User can not inject new Agreement with a file extension different from PDF' do
    login_as users(:pablito), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      find('#menu-vista-global-convenios').click
    end

    assert_content('Vista Global de Convenios')
    find_link('Subir un convenio existente').click

    assert_content('Crear Nuevo Convenio')

    page.execute_script('$("input[type=file]").show()')
    attach_file '_agreements_global_file', Rails.root.join('test/files/sample-pdf/content.txt')

    find("#select2-_agreements_global_service_consumer_organization_id-container").click
    find_all(".select2-results__option")[1].click

    find("#select2-agreement_service_provider_organization_id-container").click
    find_all(".select2-results__option")[2].click

    click_button 'Crear Nuevo Convenio'

    assert_content("No se pudo guardar el convenio")
    assert_content("El archivo debe ser un pdf")
  end

  test 'GobDigital User can not inject new Agreement without services' do
    login_as users(:pablito), scope: :user
    visit root_path

    find('#user-menu').click
    within '#user-menu' do
      find('#menu-vista-global-convenios').click
    end

    assert_content('Vista Global de Convenios')
    find_link('Subir un convenio existente').click

    assert_content('Crear Nuevo Convenio')

    page.execute_script('$("input[type=file]").show()')
    attach_file '_agreements_global_file', Rails.root.join('test/files/sample-pdf/content.pdf')

    find("#select2-_agreements_global_service_consumer_organization_id-container").click
    find_all(".select2-results__option")[1].click

    find("#select2-agreement_service_provider_organization_id-container").click
    find_all(".select2-results__option")[2].click

    click_button 'Crear Nuevo Convenio'

    assert_content("No se pudo crear el convenio")
    assert_content("Services no puede estar en blanco")
  end

end
