require 'socket'

module UrlHelper

  def fully_qualified_work_url( id )
    "#{public_site_url}#{locally_hosted_work_url( id )}"
  end

  def locally_hosted_work_url( id )
    "/public_view/#{id}"
  end

  def public_site_url
    return "#{protocol}://#{hostname}"
  end

  def orcid_oauth_url
    redirect = Rails.application.routes.url_helpers.landing_orcid_url
    orcid_client_id = Rails.application.credentials.orcid_client_id
    orcid_scopes = Rails.application.credentials.orcid_scopes
    orcid_base_url = Rails.application.credentials.orcid_base_url

    "#{orcid_base_url}/oauth/authorize?client_id=#{orcid_client_id}&response_type=code&scope=#{orcid_scopes}&redirect_uri=#{redirect}"
  end

  private

  def hostname
    return ENV['SERVICE_CNAME'] unless Rails.env.development?
    return 'localhost:3000'
  end

  def protocol
    return 'https' unless Rails.env.development?
    return 'http'
  end
end
