module Api
  module V1
    class CoursesController < BaseController
      before_action :set_course, only: %i[ show update destroy ]
      before_action :require_course_access!, only: %i[ show ]
      before_action :require_teacher!, only: %i[ create ]
      before_action :require_course_owner!, only: %i[ update destroy ]

      def index
        courses = current_user.accessible_courses.includes(:user, :enrollments).order(created_at: :desc)
        render json: { courses: courses.map { |course| serialize_course(course) } }, status: :ok
      end

      def show
        render json: { course: serialize_course(@course, include_students: @course.owned_by?(current_user)) }, status: :ok
      end

      def create
        course = current_user.courses.build(course_params)

        if course.save
          render json: { course: serialize_course(course) }, status: :created
        else
          render json: { errors: course.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @course.update(course_params)
          render json: { course: serialize_course(@course) }, status: :ok
        else
          render json: { errors: @course.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @course.destroy!
        head :no_content
      end

      private

      def set_course
        @course = Course.includes(:user, :enrolled_students).find(params.expect(:id))
      end

      def course_params
        params.expect(course: [ :title, :description ])
      end

      def require_course_access!
        return if current_user.can_view_course?(@course)

        render json: { error: "Access denied. You are not enrolled in this course." }, status: :forbidden
      end

      def require_teacher!
        return if current_user.can_manage_courses?

        render json: { error: "Access denied. Only teachers can manage courses." }, status: :forbidden
      end

      def require_course_owner!
        return if current_user.can_modify_course?(@course)

        render json: { error: "Access denied. You can only manage your own courses." }, status: :forbidden
      end

      def serialize_course(course, include_students: false)
        payload = {
          id: course.id,
          title: course.title,
          description: course.description,
          join_code: course.owned_by?(current_user) ? course.join_code : nil,
          student_count: course.enrollments.size,
          created_at: course.created_at,
          updated_at: course.updated_at,
          instructor: course.user ? { id: course.user.id, email: course.user.email } : nil,
          can_modify: current_user.can_modify_course?(course)
        }

        if include_students
          payload[:students] = course.enrolled_students.map { |student| { id: student.id, email: student.email } }
        end

        payload
      end
    end
  end
end
