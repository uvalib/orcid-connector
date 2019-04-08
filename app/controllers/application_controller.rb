class ApplicationController < ActionController::Base
  before_action :check_netbadge

  def check_netbadge
    if request.headers['USER'].present?
      @user_id = request.headers['USER']

    elsif !Rails.env.production?
      @user_id = params['user'] || 'naw4t'

    else
      render :not_authorized
      return false
    end
  end
end
