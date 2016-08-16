require "test_helper"

class CreateAgreementTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  def create_valid_service!
    service = Service.create!(
      organization: organizations(:segpres),
      name: 'test-service',
      spec_file: StringIO.new(VALID_SPEC),
      backwards_compatible: true
    )
    service.create_first_version(users(:pablito))
    service
  end

  setup do
    create_valid_service!
    login_as users(:pedro), scope: :user
    visit root_path
    find('#user-menu').click
    find_link('agreements').click
    find_link('Crear Nuevo Convenio').click
  end

  test "Attempt to create an agreement without data" do
    click_button "Crear Solicitud"
    assert_content page, "No se pudo guardar el convenio debido a 3 errores"
  end

  test "Attempt to create an agreement without a service" do

    find('#select2-agreement_service_provider_organization_id-container').click
    results = find_all(".select2-results__option")
    results[1].click
    click_button "Crear Solicitud"
    assert_content page, "No se pudo guardar el convenio debido a 1 error"

  end

  test "Create a valid agreement" do
    find('#select2-agreement_service_provider_organization_id-container').click
    find_all(".select2-results__option")[1].click
    find_all("input[type='checkbox']")[1].click
    click_button "Crear Solicitud"
    assert_content page, "Convenio creado correctamente"
  end

end
