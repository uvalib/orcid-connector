class VersionController < ApplicationController

  # the response
  class VersionResponse

    attr_accessor :build

    def initialize( build )
      @build = build
    end
  end

  # # GET /api/version
  # # GET /api/version.json
  def index
    response = VersionResponse.new( BUILD_VERSION )
    render json: response, :status => 200
  end

end
