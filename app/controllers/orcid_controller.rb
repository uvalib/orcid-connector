class OrcidController < ApplicationController
  # Adds ORCID handling behavior to the controller.
  include OrcidBehavior

  def landing
    #register orcid
    orcid_response = Orcid.token_exchange(params[:code])
    orcid_response_body = JSON.parse orcid_response.body

    if orcid_response.code == 200 && apply_orcid(orcid_response_body)
      flash[:notice] = "Your ORCID account was successfully linked."
    else
      error = params['error_description']
      flash[:alert] = "There was a problem linking your ORCID account. #{error}."
    end

    redirect_to root_path
  end


  def destroy
    if Orcid.remove(current_user)
      flash[:notice] = 'Your ORCID ID was successfully removed'
    else
      flash[:error] = 'The was a problem removing your ORCID ID'
    end
    redirect_to root_path
  end
end
