# Seeds for development and testing

teacher = User.find_or_create_by!(email: "teacher@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :teacher
end

student = User.find_or_create_by!(email: "student@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :student
end

cs_course = Course.find_or_create_by!(title: "Introduction to Computer Science", user: teacher) do |c|
  c.description = "Learn the basics of programming, algorithms, and web development."
end

calc_course = Course.find_or_create_by!(title: "Calculus I", user: teacher) do |c|
  c.description = "Differential and integral calculus with applications."
end

Enrollment.find_or_create_by!(user: student, course: cs_course)

puts "Seeded #{User.count} users, #{Course.count} courses, and #{Enrollment.count} enrollments."
puts "Join codes -> #{cs_course.title}: #{cs_course.join_code} | #{calc_course.title}: #{calc_course.join_code}"
