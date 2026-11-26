class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: "is already enrolled in this course" }
  validate :cannot_enroll_in_own_course

  private

  def cannot_enroll_in_own_course
    if course.present? && course.owned_by?(user)
      errors.add(:base, "Course owners cannot enroll as students in their own course")
    end
  end
end
