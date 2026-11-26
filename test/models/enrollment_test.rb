require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    @teacher_one = users(:teacher_one)
    @student = users(:student)
    @physics = courses(:one)
    @chemistry = courses(:two)
  end

  test "student can enroll in a course they are not yet in" do
    enrollment = Enrollment.new(user: @student, course: @chemistry)
    assert enrollment.valid?
  end

  test "cannot enroll twice in the same course" do
    duplicate = Enrollment.new(user: @student, course: @physics)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already enrolled in this course"
  end

  test "course owner cannot enroll as a student in their own course" do
    self_enrollment = Enrollment.new(user: @teacher_one, course: @physics)
    assert_not self_enrollment.valid?
    assert_includes self_enrollment.errors[:base], "Course owners cannot enroll as students in their own course"
  end
end
