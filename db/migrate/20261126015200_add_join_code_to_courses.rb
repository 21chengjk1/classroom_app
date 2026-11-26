class AddJoinCodeToCourses < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :join_code, :string

    reversible do |dir|
      dir.up do
        Course.reset_column_information
        Course.find_each do |course|
          code = loop do
            candidate = SecureRandom.alphanumeric(6).upcase
            break candidate unless Course.exists?(join_code: candidate)
          end
          course.update_column(:join_code, code)
        end
      end
    end

    change_column_null :courses, :join_code, false
    add_index :courses, :join_code, unique: true
  end
end
