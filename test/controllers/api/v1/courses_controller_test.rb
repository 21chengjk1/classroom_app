require "test_helper"

class Api::V1::CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_one = users(:teacher_one)
    @teacher_two = users(:teacher_two)
    @student = users(:student)
    @course = courses(:one)
    @other_course = courses(:two)
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

  test "student only sees enrolled courses and cannot view unenrolled courses" do
    headers = auth_headers_for(@student)

    get api_v1_courses_url, headers: headers, as: :json
    assert_response :ok
    courses = JSON.parse(response.body)["courses"]
    assert_equal [ @course.id ], courses.map { |c| c["id"] }
    assert_nil courses.first["join_code"]
    assert_equal false, courses.first["can_modify"]

    get api_v1_course_url(@course), headers: headers, as: :json
    assert_response :ok
    assert_equal false, JSON.parse(response.body).dig("course", "can_modify")

    get api_v1_course_url(@other_course), headers: headers, as: :json
    assert_response :forbidden
  end

  test "student cannot create, update, or delete courses" do
    headers = auth_headers_for(@student)

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

  test "teacher sees own courses with join code and roster, and can create, update, and destroy" do
    headers = auth_headers_for(@teacher_one)

    get api_v1_course_url(@course), headers: headers, as: :json
    assert_response :ok
    course_json = JSON.parse(response.body)["course"]
    assert_equal @course.join_code, course_json["join_code"]
    assert_equal [ @student.email ], course_json["students"].map { |s| s["email"] }

    assert_difference("Course.count", 1) do
      post api_v1_courses_url,
        headers: headers,
        params: { course: { title: "Linear Algebra", description: "Vectors and matrices" } },
        as: :json
    end
    assert_response :created
    created = JSON.parse(response.body)["course"]
    assert_equal "Linear Algebra", created["title"]
    assert_match(/\A[A-Z0-9]{6}\z/, created["join_code"])
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

  test "teacher cannot view, update, or destroy another teacher's course unless enrolled" do
    headers = auth_headers_for(@teacher_two)

    get api_v1_course_url(@course), headers: headers, as: :json
    assert_response :forbidden

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
