require "test_helper"

class WorkerControllerTest < ActionDispatch::IntegrationTest
  test "should get dashboard" do
    get worker_dashboard_url
    assert_response :success
  end
end
