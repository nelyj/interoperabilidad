require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get visual_components" do
    get static_pages_visual_components_url
    assert_response :success
  end

end
