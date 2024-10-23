require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    # Get the root URL
    get root_url

    # Assert that the response was successful
    assert_response :success
    
    # Assert that the response body contains the welcome text
    assert_select "h1", "Welcome to the sheet management service"
  end
end
