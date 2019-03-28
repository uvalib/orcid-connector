class Orcid
  include HTTParty

  base_uri Rails.application.credentials.orcid_access_url

  def self.auth
    @@auth ||= {auth: Rails.application.credentials.service_api_token}
  end


  def self.find_user cid
    self.get("/cid/#{cid}", query: auth)
  end

end

