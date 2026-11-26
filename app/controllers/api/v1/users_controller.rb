module Api
  module V1
    class UsersController < BaseController
      def me
        render json: { user: serialize_user(current_user) }, status: :ok
      end
    end
  end
end
