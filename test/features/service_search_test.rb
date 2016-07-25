require "test_helper"
require_relative 'support/ui_test_helper'

class ServiceSearchTest < Capybara::Rails::TestCase
  include UITestHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    @service_v = Service.create!(
      name: "PetsServiceName",
      organization: organizations(:minsal),
      spec_file: File.open(Rails.root / "test/files/sample-services/petsfull.yaml")
    ).create_first_version(users(:perico))
    @service2_v = Service.create!(
      name: "MicroServicio",
      organization: organizations(:segpres),
      spec_file: File.open(Rails.root / "test/files/sample-services/Micro_Servicio_ROLES_v0.9.yaml")
    ).create_first_version(users(:perico))
  end

  test "Search service by name #1" do
    visit root_path
    fill_in 'search-service', :with => "Pets"
    find_by_id('search-service').send_keys :enter
    assert_content page, "This is a sample server Petstore server"
  end

  test "Search service by name #2" do
    visit root_path
    fill_in 'search-service', :with => "Micro"
    find_by_id('search-service').send_keys :enter
    assert_content page, "Micro Servicio para ver Roles y Cargos"
  end

  test "Search service by organization" do
    visit root_path
    fill_in 'search-service', :with => "Ministerio de Salud"
    find_by_id('search-service').send_keys :enter
    assert_content page, "This is a sample server Petstore server"
  end

  test "Search service by organization initial" do
    visit root_path
    fill_in 'search-service', :with => "segpres"
    find_by_id('search-service').send_keys :enter
    assert_content page, "Micro Servicio para ver Roles y Cargos"
  end

  test "Search service by description" do
    visit root_path
    fill_in 'search-service', :with => "descriptive sentence"
    find_by_id('search-service').send_keys :enter
    assert_content page, "servicio_1"
  end

  test "Search results not found" do
    visit root_path
    fill_in 'search-service', :with => "Zanahoria"
    find_by_id('search-service').send_keys :enter
    assert_content page, "No se han encontrado resultados"
  end
end
