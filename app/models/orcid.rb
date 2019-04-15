module Orcid
  include HTTParty
  base_uri Rails.application.credentials.orcid_access_url
  format :json

  def self.auth
    @@auth ||= {auth: Rails.application.credentials.service_api_token}
  end

  def self.find_user cid
    response = self.get("/cid/#{cid}", query: auth)
    if response.success?
      response['results'].first
    else
      {}
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
    url = "#{self.url}/cid/#{id}?auth=#{self.authtoken}"
    status, _ = rest_delete( url )
    return status
  end

  def self.token_exchange code
    begin
      path = "#{Rails.application.credentials.orcid_base_url}/oauth/token"
      self.post(path, {
        body: {
          client_id: Rails.application.credentials.orcid_client_id,
          client_secret: Rails.application.credentials.orcid_client_secret,
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
end

