class Course < ApplicationRecord
    belongs_to :user

    audited
end
