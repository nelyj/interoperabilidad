require "test_helper"
require_relative 'support/ui_test_helper'
require_relative "support/agreement_creation_helper"

class AnonymousUserCantViewAgreementsTest < Capybara::Rails::TestCase
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  test "anonymous user can't view agreements list" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit organization_agreements_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Convenios Subsecretaría General de La Presidencia")
    assert page.has_content?("Para revisar convenios por favor identifíquese con su clave única")
  end

  test "anonymous user can't create new agreement" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_path(agreement.service_consumer_organization)
    assert page.has_no_content?("Crear Nuevo Convenio Subsecretaría General de La Presidencia")
    assert page.has_content?("Para crear convenios por favor identifíquese con su clave única")
  end

  test "anonymous user can't create new agreement revision" do
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    visit new_organization_agreement_agreement_revision_path(agreement.service_consumer_organization, agreement)
    assert page.has_no_content?("Nueva Versión")
    assert page.has_content?("Para crear convenios por favor identifíquese con su clave única")
  end
end
