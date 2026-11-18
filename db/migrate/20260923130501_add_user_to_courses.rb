class AddUserToCourses < ActiveRecord::Migration[8.1]
  def change
    add_reference :courses, :user, null: true, foreign_key: true
  end
end
