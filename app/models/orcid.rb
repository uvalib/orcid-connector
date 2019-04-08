class Orcid
  include HTTParty

  base_uri Rails.application.credentials.orcid_access_url

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

end

