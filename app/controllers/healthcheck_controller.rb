class HealthcheckController < ApplicationController

  # the basic health status object
  class Health
    attr_accessor :healthy
    attr_accessor :message

    def initialize( status, message )
      @healthy = status
      @message = message
    end

  end

  # the response
  class HealthCheckResponse

    attr_accessor :orcid_service
    attr_accessor :userinfo_service

    def is_healthy?
      @orcid_service.healthy &&
      @userinfo_service.healthy
    end
  end

  # # GET /healthcheck
  # # GET /healthcheck.json
  def index
    response = make_response
    if response.is_healthy?
      render json: response, :status => 200
    else
      Rails.logger.error "Healthcheck Failure: #{response}"
      render json: response, :status => 500
    end
  end

  private

  def make_response
    r = HealthCheckResponse.new
    r.orcid_service = orcid_service_health
    r.userinfo_service = userinfo_service_health

    return( r )
  end

  def orcid_service_health
    status = Orcid.healthcheck
    return Health.new(status, status == true ? "" : "ORCID Service (#{Orcid.base_uri}) unavailable")
  end

  def userinfo_service_health
    status = UserInfoClient.healthcheck
    return Health.new(status, status == true ? "" : "UserInfo Service (#{UserInfoClient.base_uri}) unavailable")
  end

end
