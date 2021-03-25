class ApplicationController < ActionController::Base

  def check_netbadge
    if request.headers['HTTP_REMOTE_USER'].present?
      @user_id = request.headers['HTTP_REMOTE_USER']

    elsif !Rails.env.production? || ENV['SKIP_NETBADGE']
      @user_id = params['user'] || 'naw4t'

    else
      redirect_to '/404'
      return false
    end
    @current_user = User.find(@user_id)
  end

  def current_user
    @current_user
  end
end
