class User

  attr_accessor :user_id, :orcid_id, :orcid_url

  def self.find user_id
    user = User.new
    user.user_id = user_id
    o_user = Orcid.find_user(user_id)
    if o_user.present?
      user.orcid_id = o_user['orcid']
      user.orcid_url = o_user['uri']
    end
    user
  end
end
