require "test_helper"
require_relative 'support/ui_test_helper'
require_relative 'support/agreement_creation_helper'

class AgreementsNotificationsTest < Capybara::Rails::TestCase
  include UITestHelper
  include AgreementCreationHelper
  include Warden::Test::Helpers
  after { Warden.test_reset! }

  setup do
    login_as users(:pedro), scope: :user
    visit root_path
  end

  test "Creator is notified when agreement draft is validated" do
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    assert agreement.state == "draft"
    within ".notifications-box" do
      assert_content 0
    end
    agreement.validate_draft(users(:pedro))
    agreement.last_revision.send_notifications

    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')

    within ".notifications-box" do
      assert_content 1
    end
  end

  test "All Responsables are notified just onece when agreement is modified" do
    assert_not find(".notifications-box")[:class].include?('with-notifications')
    agreement = create_valid_agreement!(organizations(:segpres), organizations(:sii))
    assert agreement.state == "draft"
    within ".notifications-box" do
      assert_content 0
    end
    agreement.validate_draft(users(:pedro))
    agreement.last_revision.send_notifications

    #Is not posible to sign a document on tests
    new_revision = agreement.new_revision(users(:pedro),"signed_draft","Manually Sign Draft","", agreement.last_revision.file)
    new_revision.send_notifications
    assert agreement.state.include?("signed_draft")

    visit root_path
    assert_content "Directorio de Servicios"
    assert find(".notifications-box")[:class].include?('with-notifications')
    byebug
    within ".notifications-box" do
      assert_content 2
    end
  end

end
