class OrcidController < ApplicationController
  def landing
    #register orcid
    byebug
    redirect_to controller: :dashboard, action: :show
  end
end
