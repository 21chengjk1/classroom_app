require "test_helper"

class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = users(:teacher_one)
  end

  test "signup creates a student and dispatches a JWT" do
    assert_difference("User.count", 1) do
      post api_v1_signup_url,
        params: {
          user: {
            email: "newstudent@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        },
        as: :json
    end

    assert_response :created
    assert_match(/^Bearer .+/, response.headers["Authorization"])

    body = JSON.parse(response.body)
    assert_equal "newstudent@example.com", body.dig("user", "email")
    assert_equal "student", body.dig("user", "role")
    assert_equal false, body.dig("user", "can_manage_courses")
  end

  test "login dispatches JWT, me succeeds with JWT, and logout revokes JWT" do
    post api_v1_login_url,
      params: { user: { email: @teacher.email, password: "password123" } },
      as: :json

    assert_response :ok
    token = response.headers["Authorization"]
    assert_match(/^Bearer .+/, token)

    get api_v1_me_url, headers: { "Authorization" => token }, as: :json
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal @teacher.email, body.dig("user", "email")
    assert_equal true, body.dig("user", "can_manage_courses")

    delete api_v1_logout_url, headers: { "Authorization" => token }, as: :json
    assert_response :ok

    # Revoked token should no longer authenticate
    get api_v1_me_url, headers: { "Authorization" => token }, as: :json
    assert_response :unauthorized
  end

  test "me returns unauthorized without token" do
    get api_v1_me_url, as: :json
    assert_response :unauthorized
  end
end
