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
    orcid_client_id = ENV['ORCID_CLIENT_ID']
    orcid_scopes = ENV['ORCID_SCOPES']
    orcid_base_url = ENV['ORCID_BASE_URL']

    "#{orcid_base_url}/oauth/authorize?client_id=#{orcid_client_id}&response_type=code&scope=#{orcid_scopes}&redirect_uri=#{redirect}"
  end

  private

  def hostname
    return ENV['SERVICE_CNAME'] unless Rails.env.development?
    port = Rails::Server::Options.new.parse!(ARGV)[:Port] || 3000 rescue 3000
    return "localhost:#{port}"
  end

  def protocol
    return 'https' unless Rails.env.development?
    return 'http'
  end
end
