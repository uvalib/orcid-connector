class Api::UsersController < ApplicationController
  before_action :check_token

  TOKEN = ENV['API_TOKEN']

  def show
    user = User.find(params[:id])
    if user.errors.none?
      render json: {
        user_id: user.user_id,
        orcid_id: user.orcid_id,
        orcid_token: user.orcid_access_token
      }
    else
      render json: {errors: user.errors['base']}, status: 500
    end
  end

  private
  def check_token
    authenticate_or_request_with_http_token do |token, options|
      # Compare the tokens in a time-constant manner, to mitigate
      # timing attacks.
      ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
    end
  end
end
