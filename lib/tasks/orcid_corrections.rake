namespace :orcid do

  desc "Updates UVA employment and education for all linked orcid accounts"
  task :correct_all, [:start_at] => [:environment] do |t, args|
    users = Orcid.all_users
    puts "Correcting ORCID Employment and Education for #{users.count} users starting in 5 seconds..."
    sleep 5
    args.with_defaults(start_at: 0)
    start_at = args.start_at.to_i

    users.each_with_index do |u, i|
      next if i < start_at
      sleep(1)
      puts "##{i} processing #{u['cid']}: #{u['orcid']}"
      correct_orcid(u)
    end
  end

  desc "Updates UVA employment and education for all linked orcid accounts"
  task :correct_one, [:user_id] => [:environment] do |t, args|
    user = Orcid.find_user(args.user_id)
    puts "processing #{user['cid']}: #{user['orcid']}"
    correct_orcid(user)
  end


  def correct_orcid orcid_user

    user = User.find(orcid_user['cid'])
    if user.orcid_access_token.nil?
      puts "No access token for #{orcid_user['cid']}"
      return
    end

    user_info = UserInfoClient.find_user(orcid_user['cid'])
    if user_info.empty?
      puts "No user info for #{orcid_user['cid']}"
      return
    end
    # pull orcid fields
    orcid_has = orcid_emp_edu(user)

    puts user_info['description']

    # find if emp and/or edu should be applied
    user_needs = {edu: false, emp: false}
    if user_info['description']
      user_info['description'].each do |role|
        if role.match? /Staff|Employee|Faculty|Worker/i
          user_needs[:emp] = true
        elsif role.match? /Student|Alumni/i
          user_needs[:edu] = true
        end
      end
    end

    if !user_needs[:emp] && !user_needs[:edu]
      puts "Nothing needed for #{user.user_id}; orcid_has: #{orcid_has}"
      return
    end

    # needs employment
    if user_needs[:emp]
      put_code = orcid_has[:emp] && orcid_has[:emp][:put_code]
      update_orcid(user, 'employment', put_code)
    end

    # needs edu
    if user_needs[:edu]
      put_code = orcid_has[:edu] && orcid_has[:edu][:put_code]
      update_orcid(user, 'education', put_code)
    end

  end


  ## Helpers ##


  # return structure {emp: {put_code: ''}, edu: false, }
  def orcid_emp_edu(user)
    result = {edu: false, emp: false}

    resp = HTTParty.get("/#{user.orcid_id}/record",
      base_uri: ENV['ORCID_API_URL'],
      headers: {
        "Authorization" => "Bearer #{user.orcid_access_token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    )
    if resp.success?
      body = resp.parsed_response
      # traverse json to look for Libra's client ID in existing employments
      body['activities-summary']['employments']['affiliation-group'].each do |a|
        a['summaries'].each do |emp|
          if emp.dig('employment-summary', 'source', 'source-client-id', 'path') == ENV['ORCID_CLIENT_ID']
            # User has employment
            # save the put code for updating
            result[:emp] = {put_code: emp['employment-summary']['put-code']}
          end
        end
      end

      # find and record put_code for UVA education
      body['activities-summary']['educations']['affiliation-group'].each do |a|
        a['summaries'].each do |emp|
          if emp.dig('education-summary', 'source', 'source-client-id', 'path') == ENV['ORCID_CLIENT_ID']
            # save the put code for updating
            result[:edu] = {put_code: emp['education-summary']['put-code']}
          end
        end
      end

    else
      puts "ORCID API Error: #{user.inspect} \n#{resp.body}"
    end
    return result
  end

  EMP_PAYLOAD = <<-EMP.squish
  <employment:employment
    %s
    xmlns:employment="http://www.orcid.org/ns/employment" xmlns:common="http://www.orcid.org/ns/common"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.orcid.org/ns/employment ../employment-3.0.xsd ">
    <common:organization>
      <common:name>University of Virginia</common:name>
      <common:address>
        <common:city>Charlottesville</common:city>
        <common:region>VA</common:region>
        <common:country>US</common:country>
      </common:address>
      <common:disambiguated-organization>
        <common:disambiguated-organization-identifier>https://ror.org/0153tk833</common:disambiguated-organization-identifier>
        <common:disambiguation-source>ROR</common:disambiguation-source>
      </common:disambiguated-organization>
    </common:organization>
  </employment:employment>
  EMP

  EDU_PAYLOAD = <<-EDU.squish
  <?xml version="1.0" encoding="UTF-8"?>
  <education:education
    %s
    xmlns:common="http://www.orcid.org/ns/common" xmlns:education="http://www.orcid.org/ns/education"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.orcid.org/ns/education ../education-3.0.xsd ">
    <common:organization>
      <common:name>University of Virginia</common:name>
      <common:address>
        <common:city>Charlottesville</common:city>
        <common:region>VA</common:region>
        <common:country>US</common:country>
      </common:address>
      <common:disambiguated-organization>
        <common:disambiguated-organization-identifier>https://ror.org/0153tk833</common:disambiguated-organization-identifier>
        <common:disambiguation-source>ROR</common:disambiguation-source>
      </common:disambiguated-organization>
    </common:organization>
  </education:education>
  EDU

  def update_orcid(user, type, put_code)
    # Create based on type

    payload = if type == 'employment'
      EMP_PAYLOAD
    elsif type == 'education'
      EDU_PAYLOAD
    else
      raise 'type needs to match the orcid API path'
    end

    # insert put-code if present
    put_arg = put_code ? "put-code=\"#{put_code}\"" : ''
    payload = payload % [put_arg]

    http_options = { base_uri: ENV["ORCID_API_URL"],
      format: :xml,
      body: payload,
      headers: {
        "Authorization" => "Bearer #{user.orcid_access_token}",
        "content-type" => "application/xml",
        "accept" => "application/xml"
      }
    }
    orcid_resp, action = nil

    if put_code
      # update existing affiliation
      orcid_resp = HTTParty.put("/#{user.orcid_id}/#{type}/#{put_code}", http_options )
      action = 'update'
    else
      # create affiliation
      orcid_resp = HTTParty.post("/#{user.orcid_id}/#{type}", http_options )
      action = 'create'
    end

    if orcid_resp.success?
      puts "Success: #{action} UVA #{type} for #{user.user_id}"
    else
      puts "Error: #{action} UVA #{type} for #{user.inspect} response:\n #{orcid_resp}"
    end

  end



  def remove_orcid(user, type, put_code)
    # api based on type
    raise 'type needs to match the orcid API path' unless ['employment', 'education'].include?(type)
    raise 'Put code required to delete' if put_code.nil?

    deleted_resp = HTTParty.delete("/#{user.orcid_id}/#{type}/#{put_code}",
      base_uri: ENV["ORCID_API_URL"],
      headers: {
        "Authorization" => "Bearer #{user.orcid_access_token}",
        "content-type" => "application/json",
      })
    if deleted_resp.code == 204
      puts "UVA #{type} for #{user.user_id} successfully deleted"
    else
      # create  failure
      puts "Failed to delete #{type} in ORCID: #{deleted_resp} \n#{user}"
    end
  end
end