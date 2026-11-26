module Api
  module V1
    class EnrollmentsController < BaseController
      def create
        join_code = params[:join_code].to_s.strip.upcase
        if join_code.blank?
          return render json: { error: "Join code is required." }, status: :unprocessable_content
        end

        course = Course.includes(:user, :enrollments).find_by(join_code: join_code)
        unless course
          return render json: { error: "Invalid join code. No matching course found." }, status: :not_found
        end

        enrollment = current_user.enrollments.build(course: course)

        if enrollment.save
          render json: {
            course: {
              id: course.id,
              title: course.title,
              description: course.description,
              join_code: nil,
              student_count: course.enrollments.count,
              created_at: course.created_at,
              updated_at: course.updated_at,
              instructor: course.user ? { id: course.user.id, email: course.user.email } : nil,
              can_modify: false
            }
          }, status: :created
        else
          render json: { error: enrollment.errors.full_messages.to_sentence }, status: :unprocessable_content
        end
      end

      def destroy
        enrollment = current_user.enrollments.find_by!(course_id: params.expect(:course_id))
        enrollment.destroy!
        head :no_content
      end
    end
  end
end
