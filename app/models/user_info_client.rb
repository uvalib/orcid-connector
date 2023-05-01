module UserInfoClient
  include HTTParty
  base_uri ENV['USERINFO_URL']
  format :json
  default_timeout 5

  def self.auth
    token = jwt_auth_token( ENV[ 'AUTH_SHARED_SECRET' ] )
    return {auth: token}
  end

  def self.find_user cid

    begin
      response = self.get("/user/#{cid.strip}", query: auth)
      if response.success?
        return response['user']
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "UserInfo Timeout: #{e}"
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "UserInfo Refused: #{e}"
    rescue SocketError => e
      Rails.logger.error "UserInfo SocketError: #{e}"
    end
    return {}
  end

  def self.healthcheck

    begin
      response = self.get("/healthcheck")
      if response.success?
        true
      else
        false
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Timeout connecting to UserInfo service #{e}"
      false
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "Connection refused to UserInfo service #{e}"
      false
    rescue SocketError => e
      Rails.logger.error "UserInfo SocketError: #{e}"
      false
    end
  end


  # create a time limited JWT for service authentication
  def self.jwt_auth_token( secret )

    # expire in 5 minutes
    exp = Time.now.to_i + 5 * 60

    # just a standard claim
    exp_payload = { exp: exp }

    return JWT.encode exp_payload, secret, 'HS256'

  end
end
