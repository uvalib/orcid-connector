class OrcidController < ApplicationController
  def landing
    #register orcid
    redirect_to controller: :dashboard, action: :show
  end
end
