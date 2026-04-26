require "test_helper"

class UpgradeControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get upgrade_show_url
    assert_response :success
  end
end
