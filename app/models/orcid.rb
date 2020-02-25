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
    if response.success? && needs_employment?(user)
      create_uva_employment(user)
    end
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

  def self.employment_payload
    <<-EMPLOYMENT.squish
    <?xml version="1.0" encoding="UTF-8"?>
    <employment:employment
      xmlns:employment="http://www.orcid.org/ns/employment" xmlns:common="http://www.orcid.org/ns/common"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.orcid.org/ns/employment ../employment-2.0.xsd ">
    <employment:organization>
      <common:name>University of Virginia</common:name>
      <common:address>
        <common:city>Charlottesville</common:city>
        <common:region>VA</common:region>
        <common:country>US</common:country>
      </common:address>
      <common:disambiguated-organization>
        <common:disambiguated-organization-identifier>2358</common:disambiguated-organization-identifier>
        <common:disambiguation-source>RINGGOLD</common:disambiguation-source>
        </common:disambiguated-organization>
    </employment:organization>
    </employment:employment>
    EMPLOYMENT
  end

  def self.needs_employment?(user)
    resp = self.get("/#{user.orcid_id}/employments", base_uri: ENV['ORCID_API_URL'], headers: {
      "Authorization" => "Bearer #{user.orcid_access_token}",
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    })
    if resp.success?
      body = resp.parsed_response
      uva_employment = body['employment-summary'].find {|e| e.dig('source', 'source-client-id', 'path') == ENV['ORCID_CLIENT_ID'] }
      if uva_employment.nil?
        return true
      else
        # Employment already added
        return false
      end
    else
      #employment check failure
      Rails.logger.error "Failed to check UVA Employment in ORCID: #{resp}"
    end
  end

  def self.create_uva_employment(user)
    # Add uva employment
    created_resp = self.post("/#{user.orcid_id}/employment",
      base_uri: ENV["ORCID_API_URL"],
      format: :xml,
      body: employment_payload,
      headers: {
        "Authorization" => "Bearer #{user.orcid_access_token}",
        "content-type" => "application/xml",
        "accept" => "application/xml"
      })
    if created_resp.code == 201
      Rails.logger.info "UVA employment for #{user.user_id} successfully added"
      return true
    else
      # create employment failure
      byebug
      Rails.logger.error "Failed to create UVA Employment in ORCID: #{created_resp}"
    end
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
