class Course < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  audited

  def owned_by?(user)
    user.present? && user_id == user.id
  end
end
