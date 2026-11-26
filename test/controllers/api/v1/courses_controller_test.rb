require "test_helper"

class Api::V1::CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_one = users(:teacher_one)
    @teacher_two = users(:teacher_two)
    @student = users(:student)
    @course = courses(:one)
  end

  def auth_headers_for(user)
    post api_v1_login_url,
      params: { user: { email: user.email, password: "password123" } },
      as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  test "unauthenticated request returns 401" do
    get api_v1_courses_url, as: :json
    assert_response :unauthorized
  end

  test "student can list and view courses but cannot create, update, or delete" do
    headers = auth_headers_for(@student)

    get api_v1_courses_url, headers: headers, as: :json
    assert_response :ok
    courses = JSON.parse(response.body)["courses"]
    assert_equal 2, courses.length
    assert courses.none? { |c| c["can_modify"] }

    get api_v1_course_url(@course), headers: headers, as: :json
    assert_response :ok
    assert_equal false, JSON.parse(response.body).dig("course", "can_modify")

    assert_no_difference("Course.count") do
      post api_v1_courses_url,
        headers: headers,
        params: { course: { title: "Blocked", description: "Nope" } },
        as: :json
    end
    assert_response :forbidden

    patch api_v1_course_url(@course),
      headers: headers,
      params: { course: { title: "Hacked" } },
      as: :json
    assert_response :forbidden

    assert_no_difference("Course.count") do
      delete api_v1_course_url(@course), headers: headers, as: :json
    end
    assert_response :forbidden
  end

  test "teacher can create, update, and destroy own course" do
    headers = auth_headers_for(@teacher_one)

    assert_difference("Course.count", 1) do
      post api_v1_courses_url,
        headers: headers,
        params: { course: { title: "Linear Algebra", description: "Vectors and matrices" } },
        as: :json
    end
    assert_response :created
    created = JSON.parse(response.body)["course"]
    assert_equal "Linear Algebra", created["title"]
    assert_equal @teacher_one.email, created.dig("instructor", "email")
    assert_equal true, created["can_modify"]

    patch api_v1_course_url(@course),
      headers: headers,
      params: { course: { title: "Physics 102" } },
      as: :json
    assert_response :ok
    assert_equal "Physics 102", JSON.parse(response.body).dig("course", "title")

    assert_difference("Course.count", -1) do
      delete api_v1_course_url(@course), headers: headers, as: :json
    end
    assert_response :no_content
  end

  test "teacher cannot update or destroy another teacher's course" do
    headers = auth_headers_for(@teacher_two)

    get api_v1_course_url(@course), headers: headers, as: :json
    assert_response :ok
    assert_equal false, JSON.parse(response.body).dig("course", "can_modify")

    patch api_v1_course_url(@course),
      headers: headers,
      params: { course: { title: "Unauthorized Edit" } },
      as: :json
    assert_response :forbidden

    assert_no_difference("Course.count") do
      delete api_v1_course_url(@course), headers: headers, as: :json
    end
    assert_response :forbidden
  end
end
