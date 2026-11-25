class Course < ApplicationRecord
  belongs_to :user

  audited

  def owned_by?(user)
    user.present? && user_id == user.id
  end
end
