require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_one = users(:teacher_one)
    @teacher_two = users(:teacher_two)
    @student = users(:student)
    @course = courses(:one) # owned by teacher_one
  end

  # --- Unauthenticated Tests ---

  test "unauthenticated user is redirected to login for index" do
    get courses_url
    assert_redirected_to new_user_session_url
  end

  test "unauthenticated user is redirected to login for show" do
    get course_url(@course)
    assert_redirected_to new_user_session_url
  end

  test "unauthenticated user is redirected to login for new" do
    get new_course_url
    assert_redirected_to new_user_session_url
  end

  test "unauthenticated user cannot create course" do
    assert_no_difference("Course.count") do
      post courses_url, params: { course: { title: "New Course", description: "Desc" } }
    end
    assert_redirected_to new_user_session_url
  end

  # --- Student Tests ---

  test "student can view courses index" do
    sign_in @student
    get courses_url
    assert_response :success
  end

  test "student can view course show" do
    sign_in @student
    get course_url(@course)
    assert_response :success
  end

  test "student cannot get new course page" do
    sign_in @student
    get new_course_url
    assert_redirected_to courses_url
    assert_equal "Access denied. Only teachers can manage courses.", flash[:alert]
  end

  test "student cannot create course" do
    sign_in @student
    assert_no_difference("Course.count") do
      post courses_url, params: { course: { title: "Student Course", description: "Desc" } }
    end
    assert_redirected_to courses_url
    assert_equal "Access denied. Only teachers can manage courses.", flash[:alert]
  end

  test "student cannot edit course" do
    sign_in @student
    get edit_course_url(@course)
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
  end

  test "student cannot update course" do
    sign_in @student
    patch course_url(@course), params: { course: { title: "Hacked Title" } }
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
    @course.reload
    assert_not_equal "Hacked Title", @course.title
  end

  test "student cannot destroy course" do
    sign_in @student
    assert_no_difference("Course.count") do
      delete course_url(@course)
    end
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
  end

  # --- Teacher Owner Tests ---

  test "teacher can view index and new" do
    sign_in @teacher_one
    get courses_url
    assert_response :success

    get new_course_url
    assert_response :success
  end

  test "teacher can create course and is assigned as owner" do
    sign_in @teacher_one
    assert_difference("Course.count", 1) do
      post courses_url, params: { course: { title: "Biology 101", description: "Intro to Bio" } }
    end

    created_course = Course.last
    assert_equal "Biology 101", created_course.title
    assert_equal @teacher_one, created_course.user
    assert_redirected_to course_url(created_course)
  end

  test "teacher can edit own course" do
    sign_in @teacher_one
    get edit_course_url(@course)
    assert_response :success
  end

  test "teacher can update own course" do
    sign_in @teacher_one
    patch course_url(@course), params: { course: { title: "Updated Title" } }
    assert_redirected_to course_url(@course)
    @course.reload
    assert_equal "Updated Title", @course.title
  end

  test "teacher can destroy own course" do
    sign_in @teacher_one
    assert_difference("Course.count", -1) do
      delete course_url(@course)
    end
    assert_redirected_to courses_url
  end

  # --- Teacher Non-Owner Tests ---

  test "teacher cannot edit another teacher's course" do
    sign_in @teacher_two
    get edit_course_url(@course)
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
  end

  test "teacher cannot update another teacher's course" do
    sign_in @teacher_two
    patch course_url(@course), params: { course: { title: "Stolen Title" } }
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
    @course.reload
    assert_not_equal "Stolen Title", @course.title
  end

  test "teacher cannot destroy another teacher's course" do
    sign_in @teacher_two
    assert_no_difference("Course.count") do
      delete course_url(@course)
    end
    assert_redirected_to courses_url
    assert_equal "Access denied. You can only manage your own courses.", flash[:alert]
  end
end
