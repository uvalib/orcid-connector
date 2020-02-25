namespace :orcid do

  desc "Updates UVA employment for all linked orcid accounts"
  task update_all_employment: :environment do |t, args|
    users = Orcid.all_users

    users.each do |u|
      user = User.find(u['cid'])
      if user.orcid_access_token.nil?
        puts "No access token for #{u['cid']}"
        next
      end

      if Orcid.needs_employment?(user)
        puts "Updating Employment for #{user.user_id}"
        Orcid.create_uva_employment(user)
      else
        puts "No Employment needed for #{user.user_id}"
      end
    end
  end
end