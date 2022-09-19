namespace :orcid do

  desc "Updates UVA employment and education for all linked orcid accounts"
  task correct_all: :environment do |t, args|
    users = Orcid.all_users
    puts "Correcting ORCID Employment and Education for #{users.count} users in 5 seconds."
    sleep 5

    users.each do |u|
      puts "processing #{user['cid']}: #{user['orcid']}"
      correct_orcid u['cid']
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
      return false
    end

    user_info = UserInfoClient.find_user(user.user_id)
    if user_info.empty?
      puts "No user info for #{u['cid']}"
      return false
    end
    # pull orcid fields
    orcid_has = orcid_emp_edu(user)

    # find if emp and/or edu should be applied
    user_needs = {edu: false, emp: false}
    user_info['description'].each do |role|
      if role.match? /Staff|Employee|Faculty/i
        user_needs[:emp] = true
      else
        user_needs[:edu] = true
      end
    end

    # needs employment
    if user_needs[:emp] && !orcid_has[:emp]
      add_orcid(user, 'employment')

    # delete emp
    elsif !user_needs[:emp] && orcid_has[:emp]
      remove_orcid(user, 'employment', orcid_has[:emp][:put_code])

    # needs edu
    elsif user_needs[:edu] && !orcid_has[:edu]
      add_orcid(user, 'education')
    # delete edu
    elsif !user_needs[:edu] && orcid_has[:edu]
      remove_orcid(user, 'education', orcid_has[:edu][:put_code])
    else
      # everything is fine
      puts "Nothing changed for #{user.user_id}; user needed: #{user_needs}, orcid_has: #{orcid_has}"
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
      # traverse json to find the libra client ID
      body['activities-summary']['employments']['affiliation-group'].each do |a|
        a['summaries'].each do |emp|
          if emp.dig('employment-summary', 'source', 'source-client-id', 'path') == ENV['ORCID_CLIENT_ID']
            # User has employment
            # save the put code in case this needs to be deleted
            result[:emp] = {put_code: emp['employment-summary']['put-code']}
          end
        end
      end

      # find and record put_code for UVA education
      body['activities-summary']['educations']['affiliation-group'].each do |a|
        a['summaries'].each do |emp|
          if emp.dig('education-summary', 'source', 'source-client-id', 'path') == ENV['ORCID_CLIENT_ID']
            # save the put code in case this needs to be deleted
            result[:edu] = {put_code: emp['education-summary']['put-code']}
          end
        end
      end

      return result
    else
      raise "ORCID API Error: #{user} \n#{resp.body}"
    end
  end

  EMP_PAYLOAD = <<-EMP.squish
  <employment:employment
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

  def add_orcid(user, type)
    # Create based on type
    payload = if type == 'employment'
      EMP_PAYLOAD
    elsif type == 'education'
      EDU_PAYLOAD
    else
      raise 'type needs to match the orcid API path'
    end
    created_resp = HTTParty.post("/#{user.orcid_id}/#{type}",
      base_uri: ENV["ORCID_API_URL"],
      format: :xml,
      body: payload,
      headers: {
        "Authorization" => "Bearer #{user.orcid_access_token}",
        "content-type" => "application/xml",
        "accept" => "application/xml"
      })
    if created_resp.code == 201
      puts "UVA #{type} for #{user.user_id} successfully added"
      return true
    else
      # create  failure
      puts "Failed to create UVA #{type} in ORCID: #{created_resp} \n #{user}"
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