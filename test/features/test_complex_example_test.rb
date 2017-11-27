require "test_helper"
require 'yaml'
require_relative 'support/ui_test_helper'

class TestSimpleExampleTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pablito), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('services').click
    find_link('Crear Servicio').click
    fill_in 'service_name', :with => "Compex Test"
    page.execute_script('$("input[type=file]").show()')
  end

  test "complex service example" do

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'ComplexExample.yaml')

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    click_button "Probar Servicio"

    find("#try-service").click

    page.must_have_content('Respuesta')
    assert_content 'pedro@dominio.com'
    assert_content 'Juan Andres'
    assert_content 'Perez Cortez'


  end

  test "complex service post example" do

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'ComplexExample.yaml')

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    find('a .btn-status.full.success').click

    assert_content page, "Crear persona"

    click_button "Probar Servicio"

    within ".console" do

      expand_console_form(page)

      fill_in 'nombres', :with => "Jose"
      fill_in 'apellidos', :with => "Altuve"
      fill_in 'email', :with => "jaltuve@dominio.com"

      find('.add-element').click

      fill_in 'numero', :with => "77777777"

      find("#try-service").click

      page.must_have_content('Respuesta')

      assert_content 'Respuesta'
      assert_content 'Jose'
      assert_content 'Altuve'
      assert_content '77777777'
    end

  end


  test "complex service delete example" do

    attach_file 'service_spec_file', Rails.root.join(
      'test', 'files', 'sample-services', 'ComplexExample.yaml')


    swagger = YAML.load_file("#{Rails.root}/test/files/sample-services/ComplexExample.yaml")
    url_post_persona_example = swagger['host']+swagger['basePath']+swagger['paths'].keys.first

    response = RestClient::Request.execute(
        method: :post,
        url: "#{swagger['schemes'].first}://#{url_post_persona_example}",
        payload: {persona: {nombres: "Jose", apellidos: "Altuve"}}
      )
    json_response = JSON.parse(response.body)

    click_button "Crear Servicio"
    assert_content page, "Servicio creado correctamente"

    find('a .btn-status.danger.full').click

    assert_content page, "Eliminando Personas"

    click_button "Probar Servicio"

    within ".console" do
      fill_in 'id', :with => json_response["persona"]["id"]
      click_button "Enviar"
      assert_content 'Respuesta'
      assert_content 'Persona eliminada correctamente.'
    end

  end


end
