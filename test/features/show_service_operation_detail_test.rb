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
    @service_v2 = Service.create!(
      name: "PetsComplex",
      public: false,
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull-complex.json")
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

    # -------------------------------------------
    skip("Skipping because test fail randoming")
    # -------------------------------------------

    echo_version = Service.create!(
      name: "SimpleEchoServiceToTest",
      public: true,
      organization: organizations(:sii),
      spec_file: File.open(Rails.root / "test/files/sample-services/echo.yaml")
    ).create_first_version(users(:pedro))
    visit organization_service_service_version_path(
      echo_version.organization, echo_version.service, echo_version
    )
    find(".container-verbs a", text: "GET/test-path/{id}").trigger('click')
    click_button "Probar Servicio"
    assert_content("Parámetros")
    within ".console" do
      fill_in 'id', with: "value-for-param-id"
      click_button "Enviar"
      assert_content 'Respuesta'
      assert_content "http://mazimi-prod.apigee.net/test-path/value-for-param-id"
    end
  end

  test "Show only mock test service form for users not allowed to use the service" do
    login_as users(:pablito)
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    click_button "Probar Servicio"
    within ".console" do
      assert_content "Parámetros"
      assert_content "Servicio Simulado"
    end
  end


  test "Show only mock test service form for not autenticated users" do
    visit organization_service_service_version_path(
      @service_v.organization, @service_v.service, @service_v
    )
    find(".container-verbs a", text: "GET/users/login").click
    assert_content "Logs user into the system"
    click_button "Probar Servicio"
    within ".console" do
      assert_content "Parámetros"
      assert_content "Servicio Simulado"
    end
  end
end
