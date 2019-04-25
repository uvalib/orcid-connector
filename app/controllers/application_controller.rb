class ApplicationController < ActionController::Base
  before_action :check_netbadge

  def check_netbadge
    Rails.logger.info request.headers
    if request.headers['REMOTE_USER'].present?
      @user_id = request.headers['REMOTE_USER']

    elsif !Rails.env.production? || ENV['SKIP_NETBADGE']
      @user_id = params['user'] || 'test'

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
