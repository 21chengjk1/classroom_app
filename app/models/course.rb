class Course < ApplicationRecord
  belongs_to :user
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_students, through: :enrollments, source: :user

  validates :title, presence: true
  validates :join_code, presence: true, uniqueness: true

  before_validation :assign_join_code, on: :create

  audited

  def owned_by?(user)
    user.present? && user_id == user.id
  end

  private

  def assign_join_code
    return if join_code.present?

    self.join_code = loop do
      candidate = SecureRandom.alphanumeric(6).upcase
      break candidate unless Course.exists?(join_code: candidate)
    end
  end
end
