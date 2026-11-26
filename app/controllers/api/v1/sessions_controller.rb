module Api
  module V1
    class SessionsController < Devise::SessionsController
      protect_from_forgery with: :null_session
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        render json: {
          user: {
            id: resource.id,
            email: resource.email,
            role: resource.role,
            can_manage_courses: resource.can_manage_courses?
          }
        }, status: :ok
      end

      def respond_to_on_destroy(*_args, **_kwargs)
        if request.headers["Authorization"].present?
          render json: { message: "Logged out successfully." }, status: :ok
        else
          render json: { message: "No active session." }, status: :unauthorized
        end
      end
    end
  end
end
