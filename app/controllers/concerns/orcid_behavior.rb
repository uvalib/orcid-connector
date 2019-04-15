module OrcidBehavior
  extend ActiveSupport::Concern
  include OrcidHelper

  def apply_orcid o_response

    # Check for required keys
    unless (%w(orcid access_token refresh_token expires_in) - o_response.keys).empty?
      flash['error'] = "ORCID response was invalid."
      return false
    end

    # Check for temporary auth
    expires_in = o_response['expires_in']
    one_time_access = expires_in.seconds < 1.day
    if one_time_access
      flash['error'] = 'Please be sure to leave "Allow this permission until I revoke it" checked on the ORCID authorization page.'

      return false
    end

    expires_at = DateTime.current + expires_in.seconds
    current_user.assign_attributes(
      orcid_id: o_response['orcid'],
      orcid_access_token: o_response['access_token'],
      orcid_refresh_token: o_response['refresh_token'],
      orcid_expires_in: expires_in,
      orcid_linked_at: DateTime.current,
      orcid_scope: o_response['scope']
    )
    Orcid.update(current_user)
  end

end
