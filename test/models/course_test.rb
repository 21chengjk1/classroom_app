require "test_helper"

class CourseTest < ActiveSupport::TestCase
  setup do
    @teacher = users(:teacher_one)
    @other_user = users(:teacher_two)
    @course = courses(:one)
  end

  test "belongs to user" do
    assert_equal @teacher, @course.user
  end

  test "owned_by? checks correct owner" do
    assert @course.owned_by?(@teacher)
    assert_not @course.owned_by?(@other_user)
    assert_not @course.owned_by?(nil)
  end

  test "automatically generates a unique 6-character join code on create" do
    course = Course.create!(title: "History 101", description: "World History", user: @teacher)
    assert_match(/\A[A-Z0-9]{6}\z/, course.join_code)
  end

  test "creating and updating course creates audit records" do
    course = Course.create!(title: "Audited Course", description: "Testing audits", user: @teacher)
    assert_equal 1, course.audits.count
    assert_equal "create", course.audits.last.action

    course.update!(title: "Audited Course Updated")
    assert_equal 2, course.audits.count
    assert_equal "update", course.audits.last.action
  end
end
