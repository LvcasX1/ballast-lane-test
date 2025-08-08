require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @librarian = users(:librarian_one)
    @member = users(:member_one)
  end

  test "should get index" do
    get users_url, headers: auth_headers_for(@librarian), as: :json
    assert_response :success
  end

  test "should sign up user via /sign-up" do
    email = "user_#{SecureRandom.hex(4)}@example.com"
    assert_difference("User.count") do
      post "/sign-up", params: { user: { name: "New User", email_address: email, password: "password", password_confirmation: "password" } }, as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert body["auth_token"].present?
    assert_equal "New User", body.dig("user", "name")
    assert_equal email, body.dig("user", "email_address")
  end

  test "should show user" do
    get user_url(@member), headers: auth_headers_for(@librarian), as: :json
    assert_response :success
  end

  test "should update user" do
    patch user_url(@member), params: { user: { name: "Updated Name" } }, headers: auth_headers_for(@librarian), as: :json
    assert_response :success
    assert_equal "Updated Name", @member.reload.name
  end

  test "should destroy user" do
    fresh = User.create!(name: "Temp", email_address: "temp_#{SecureRandom.hex(4)}@example.com", password: "password", password_confirmation: "password")
    assert_difference("User.count", -1) do
      delete user_url(fresh), headers: auth_headers_for(@librarian), as: :json
    end
    assert_response :no_content
  end
end
