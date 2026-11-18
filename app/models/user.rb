class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  # 0 will be student, 1 will be teacher
  enum :role, { student: 0, teacher: 1 }, default: :student

  # Explicit RBAC permission queries
  def can_manage_courses?
    teacher?
  end

  def can_view_courses?
    student? || teacher?
  end

  has_many :courses, dependent: :destroy
  
end
