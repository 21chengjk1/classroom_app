class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # 0 will be student, 1 will be teacher
  enum :role, { student: 0, teacher: 1 }, default: :student

  has_many :courses, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_courses, through: :enrollments, source: :course

  # Explicit RBAC permission queries
  def can_manage_courses?
    teacher?
  end

  def can_view_courses?
    student? || teacher?
  end

  def enrolled_in?(course)
    course.present? && enrollments.exists?(course_id: course.id)
  end

  def can_view_course?(course)
    course.present? && (course.owned_by?(self) || enrolled_in?(course))
  end

  def can_modify_course?(course)
    can_manage_courses? && course.present? && course.user_id == id
  end

  def accessible_courses
    Course.where(id: courses.select(:id)).or(Course.where(id: enrolled_courses.select(:id)))
  end
end
