require "test_helper"
require_relative 'support/ui_test_helper'

class ShowServiceOperationDetailTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      public: false,
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:pedro))
  end

  test "Show service operation detail" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/pets/findByStatus").click
    assert_content "Finds Pets by status"
    assert_content "Multiple status values can be provided with comma seperated strings"
  end

  test "Show test service form for users allowed to use the service" do
    login_as users(:pedro)
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    click_button "Probar Servicio"
    within ".console" do
      assert_content "Parámetros"
      assert_content "URL: Query"
      assert_content "username"
      assert_content "password"
    end
  end

  test "Show test service form with raw JSON input for users allowed to use the service" do
    login_as users(:pedro)
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    click_button "Probar Servicio"
    within ".console" do
      assert_content "Parámetros"
      assert_content "URL: Query"
      fill_in "username", with: "Something"
      find("a", text: "JSON").click
      assert_content '"username": "Something"'
    end
  end

  test "Test a service using the console" do
    echo_version = Service.create!(
      name: "SimpleEchoServiceToTest",
      public: true,
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/echo.yaml")
    ).create_first_version(users(:pedro))
    visit organization_service_service_version_path(
      echo_version.organization, echo_version.service, echo_version
    )
    find(".container-verbs a", text: "GET/test-path/{id}").click
    click_button "Probar Servicio"
    within ".console" do
      fill_in 'id', with: "value-for-param-id"
      click_button "Enviar"
      assert_content 'Respuesta'
      assert_content "http://mazimi-prod.apigee.net/test-path/value-for-param-id"
    end
  end

  test "Don't show test service form for users not allowed to use the service" do
    login_as users(:pablito)
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    click_button "Probar Servicio"
    within ".console" do
      assert_no_content "Parámetros"
      assert_no_content "URL: Query"
      assert_no_content "username"
      assert_no_content "password"
      assert_content "Se requiere de un convenio activo para probar este servicio"
    end
  end

  test "Body parameters are displayed correctly" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "PUT/pets").click
    assert_content "Update an existing pet"
    find(".parameters a", text: "body").trigger('click')
    within ".schema-panel-set" do
      assert_content "name"
      assert_content "pet status in the store"
      find("a", text: "photoUrls").trigger('click')
      assert_content "(elementos)"
    end
    find(".container-verbs a", text: "POST/users/createWithList").click
    assert_content "Creates list of users with given input array"
    find(".parameters a", text: "body").trigger('click')
    within ".schema-panel-set" do
      assert_content "(elementos)"
      find("a", text: "(elementos)").trigger('click')
      assert_content "email"
      assert_content "password"
    end
  end

  test "Responses are displayed correctly" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "PUT/pets").click
    assert_content "Update an existing pet"
    within ".responses" do
      assert_content "400"
      assert_content "Invalid ID supplied"
      assert_content "404"
      assert_content "Pet not found"
      assert_content "405"
      assert_content "Validation exception"
    end
    find(".container-verbs a", text: "POST/users").click
    within ".responses" do
      assert_content "default"
      assert_content "successful operation"
    end
  end

  test "URL: Query parameters are displayed correctly" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    assert_content "URL: Query"
    within ".parameters" do
      assert_content "username"
      assert_content "password"
    end
    find(".container-verbs a", text: "GET/pets/findByStatus").click
    within ".parameters" do
      assert_content "username"
      assert_content "password"
    end
  end
end
