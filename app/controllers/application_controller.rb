class ApplicationController < ActionController::Base
  before_action :check_netbadge

  def check_netbadge
    if request.headers['USER'].present?
      @user_id = request.headers['USER']

    elsif !Rails.env.production?
      @user_id = params['user'] || 'abc123'

    else
      render :not_authorized
      return false
    end
    @current_user = User.find(@user_id)
  end

  def current_user
    @current_user
  end
end
