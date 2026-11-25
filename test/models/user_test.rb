require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @teacher = users(:teacher_one)
    @other_teacher = users(:teacher_two)
    @student = users(:student)
    @course = courses(:one) # owned by teacher_one
  end

  test "teacher can manage courses" do
    assert @teacher.can_manage_courses?
    assert_not @student.can_manage_courses?
  end

  test "user can view courses" do
    assert @teacher.can_view_courses?
    assert @student.can_view_courses?
  end

  test "only course owner can modify course" do
    assert @teacher.can_modify_course?(@course)
    assert_not @other_teacher.can_modify_course?(@course)
    assert_not @student.can_modify_course?(@course)
  end

  test "can_modify_course? returns false for nil course" do
    assert_not @teacher.can_modify_course?(nil)
  end
end
