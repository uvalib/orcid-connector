require 'test_helper'

class OrcidControllerTest < ActionDispatch::IntegrationTest
  test "should get landing" do
    get orcid_landing_url
    assert_response :success
  end

end
