module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def serialize_user(user)
        {
          id: user.id,
          email: user.email,
          role: user.role,
          can_manage_courses: user.can_manage_courses?
        }
      end

      def render_not_found
        render json: { error: "Resource not found." }, status: :not_found
      end

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
