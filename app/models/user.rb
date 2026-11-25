class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 0 will be student, 1 will be teacher
  enum :role, { student: 0, teacher: 1 }, default: :student

  has_many :courses, dependent: :destroy

  # Explicit RBAC permission queries
  def can_manage_courses?
    teacher?
  end

  def can_view_courses?
    student? || teacher?
  end

  def can_modify_course?(course)
    can_manage_courses? && course.present? && course.user_id == id
  end
end
