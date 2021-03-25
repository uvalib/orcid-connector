class ApplicationController < ActionController::Base

  def check_netbadge
    if request.headers['HTTP_REMOTE_USER'].present?
      @user_id = request.headers['HTTP_REMOTE_USER']

      # Temporary
      if @user_id == 'naw4t'
        Rails.logger.info request.headers.to_h.select { |k,v|
          ['HTTP','CONTENT','REMOTE','REQUEST','AUTHORIZATION','SCRIPT','SERVER'].any? { |s|
            k.to_s.starts_with? s
          }
        }
      end

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
