require "test_helper"
require_relative 'support/ui_test_helper'
require_relative 'support/agreement_creation_helper'

class FilterAgreementsTest < Capybara::Rails::TestCase
  include UITestHelper
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  before do
    create_valid_agreement!(organizations(:sii), organizations(:segpres))
    create_valid_agreement!(organizations(:sii), organizations(:minsal))
  end

  test "Filter/Search on the table with services of my organization" do
    login_as users(:pedro), scope: :user
    visit root_path
    find('#user-menu').click
    within('#user-menu') { click_link 'Convenios' }
    assert_content "Secretaría General de la Presidencia"
    assert_content "Ministerio de Salud"

    find('[placeholder="Buscar por nombre"]').set('Ministerio')
    assert_content "Ministerio de Salud"
    assert_no_content "Secretaría General de la Presidencia"

    find('[placeholder="Buscar por nombre"]').set('Secretaría')
    assert_no_content "Ministerio de Salud"
    assert_content "Secretaría General de la Presidencia"

    find('[placeholder="Buscar por nombre"]').set(' ')
    assert_content "Secretaría General de la Presidencia"
    assert_content "Ministerio de Salud"
  end
end
