module Orcid
  include HTTParty
  base_uri ENV['ORCID_ACCESS_URL']
  format :json
  default_timeout 5

  def self.auth

    # if we have a secret configured, use that to create a JWT
    if ENV[ 'AUTH_SHARED_SECRET' ].nil? == false
      token = jwt_auth_token( ENV[ 'AUTH_SHARED_SECRET' ] )
    else
      # otherwise use the preconfigured auth token instead
      token = ENV['SERVICE_API_TOKEN']
    end

    return {auth: token}
  end

  def self.find_user cid

    begin
      response = self.get("/cid/#{cid}", query: auth)
      if response.success?
        response['results'].first
      else
        {}
      end
    rescue Net::OpenTimeout => e
      Rails.logger.error "ORCID Timeout: #{e}"
      return {'error' => 'Timeout connecting to ORCID service'}
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "ORCID Refused: #{e}"
      return {'error' => 'Connection refused to ORCID service'}
    end
  end

  def self.healthcheck

    begin
      response = self.get("/healthcheck")
      if response.success?
        true
      else
        false
      end
    rescue Net::OpenTimeout => e
      Rails.logger.error "Timeout connecting to ORCID service #{e}"
      false
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "Connection refused to ORCID service #{e}"
      false
    end
  end

  #
  # set specified user's ORCID attributes
  #
  def self.update(user)
    path = "/cid/#{user.user_id}"
    payload =  self.construct_user_payload(user)
    response = self.put("/cid/#{user.user_id}",
                        query: auth,
                        body: payload
                       )
    return response
  end

  #
  # delete specified user's ORCID attributes
  #
  def self.remove(user)
    path = "/cid/#{user.user_id}"
    response = self.delete(path,
                        query: auth
                       )
    return response
  end

  def self.token_exchange code
    begin
      path = "#{ENV['ORCID_BASE_URL']}/oauth/token"
      self.post(path, {
        body: {
          client_id: ENV['ORCID_CLIENT_ID'],
          client_secret: ENV['ORCID_CLIENT_SECRET'],
          grant_type: 'authorization_code',
          code: code
          #   redirect_uri: landing_orcid_url
        }
      })
    rescue RestClient::Exception => e
      return e.response
    end
  end

  # construct the user attributes payload
  #
  def self.construct_user_payload(user)
    h = {}
    h['orcid'] = user.orcid_id
    h['oauth_access_token'] = user.orcid_access_token
    h['oauth_refresh_token'] = user.orcid_refresh_token
    h['scope'] = user.orcid_scope

    return h.to_json
  end

  #
  # NOT USED YET
  # construct the activity request payload
  #
  def self.construct_activity_payload( work )
    h = {}

    h['update_code'] = work.orcid_put_code if work.orcid_put_code.present?

    metadata = 'work'
    h[metadata] = {}
    h[metadata]['title'] = work.title.join( ' ' ) if work.title.present?
    h[metadata]['abstract'] = work.abstract if work.abstract.present?
    yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.published_date )
    yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.date_created ) if yyyymmdd.nil?
    h[metadata]['publication_date'] = yyyymmdd if yyyymmdd.present?
    h[metadata]['url'] = work.doi_url if work.doi_url.present?
    h[metadata]['authors'] = author_cleanup( work.authors ) if work.authors.present?
    h[metadata]['resource_type'] = map_to_orcid_type( work.resource_type ) if work.resource_type.present?

    #puts "==> #{h.to_json}"
    return h.to_json
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
