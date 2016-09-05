require "test_helper"
require_relative 'support/ui_test_helper'
require_relative 'support/agreement_creation_helper'

class SecureAgreementsTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "user for another organization can't view agreements list" do
    login_as users(:perico)
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit organization_agreements_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Convenios Subsecretaría General de La Presidencia")
    assert page.has_content?("No tiene permisos suficientes")
  end

  test "user for another organization can't create new agreement" do
    login_as users(:perico)
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Crear Nuevo Convenio Subsecretaría General de La Presidencia")
    assert page.has_content?("No tiene permisos suficientes")
  end

  test "user for another organization can't create new agreement revision" do
    login_as users(:perico)
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_agreement_revision_path(agreement.service_consumer_organization, agreement)
    assert page.has_no_content?("Nueva Versión")
    assert page.has_content?("No tiene permisos suficientes")
  end

end
