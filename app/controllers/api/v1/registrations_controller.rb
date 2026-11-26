module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      protect_from_forgery with: :null_session
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            user: {
              id: resource.id,
              email: resource.email,
              role: resource.role,
              can_manage_courses: resource.can_manage_courses?
            }
          }, status: :created
        else
          render json: {
            errors: resource.errors.full_messages
          }, status: :unprocessable_content
        end
      end
    end
  end
end
