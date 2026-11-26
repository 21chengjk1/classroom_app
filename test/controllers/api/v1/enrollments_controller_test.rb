require "test_helper"

class Api::V1::EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_one = users(:teacher_one)
    @student = users(:student)
    @physics = courses(:one)
    @chemistry = courses(:two)
  end

  def auth_headers_for(user)
    post api_v1_login_url,
      params: { user: { email: user.email, password: "password123" } },
      as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  test "student can join a course with a valid case-insensitive join code and then view it" do
    headers = auth_headers_for(@student)

    assert_difference("Enrollment.count", 1) do
      post api_v1_enrollments_url,
        headers: headers,
        params: { join_code: "  chem01 " },
        as: :json
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @chemistry.id, body.dig("course", "id")

    get api_v1_course_url(@chemistry), headers: headers, as: :json
    assert_response :ok
  end

  test "invalid join code returns 404" do
    headers = auth_headers_for(@student)

    assert_no_difference("Enrollment.count") do
      post api_v1_enrollments_url,
        headers: headers,
        params: { join_code: "NOPE99" },
        as: :json
    end

    assert_response :not_found
  end

  test "joining an already enrolled course returns 422" do
    headers = auth_headers_for(@student)

    assert_no_difference("Enrollment.count") do
      post api_v1_enrollments_url,
        headers: headers,
        params: { join_code: @physics.join_code },
        as: :json
    end

    assert_response :unprocessable_content
  end

  test "course owner cannot join their own course as a student" do
    headers = auth_headers_for(@teacher_one)

    assert_no_difference("Enrollment.count") do
      post api_v1_enrollments_url,
        headers: headers,
        params: { join_code: @physics.join_code },
        as: :json
    end

    assert_response :unprocessable_content
  end

  test "student can leave an enrolled course and loses access" do
    headers = auth_headers_for(@student)

    assert_difference("Enrollment.count", -1) do
      delete api_v1_enrollment_url(@physics.id), headers: headers, as: :json
    end

    assert_response :no_content

    get api_v1_course_url(@physics), headers: headers, as: :json
    assert_response :forbidden
  end
end
