class User
  include ActiveModel::Model

  attr_accessor :user_id, :orcid_id, :orcid_url,
    :orcid_access_token, :orcid_refresh_token, :orcid_scope,
    :orcid_linked_at, :orcid_expires_in

  def self.find user_id
    user = User.new
    user.user_id = user_id
    o_user = Orcid.find_user(user_id)
    if o_user.present?
      user.orcid_id = o_user['orcid']
      user.orcid_url = o_user['uri']
      user.orcid_access_token = o_user['oauth_access_token']
      user.errors['base'] << o_user['error'] if o_user['error']
    end
    user
  end

  def orcid_expires_at
    @orcid_expires_at ||= DateTime.current + orcid.expires_in
  end
end
