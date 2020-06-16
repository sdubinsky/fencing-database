require 'json'
require 'excon'
require 'sequel'
require 'psych'

class UpdateGfycatList
  class << self
  def get_access_token
    secrets = Psych.load_file('gfycat_secrets.yml')
    body = {
      grant_type:  "password",
      username:  secrets['username'],
      password: secrets['password'],
      client_id: secrets['client_id'],
      client_secret: secrets['client_secret']
    }
    response = Excon.post(
      "https://api.gfycat.com/v1/oauth/token",
      headers: {"Content-Type" => "application/json"},
      body: body.to_json
    )
    response = JSON.parse response.body
    response['access_token']
  end
  
  def update_gfycat_list db
    access_token = get_access_token


    #the list is just gfys that keep getting included for some reason
    old_gfycats = Gfycat.map(:gfycat_gfy_id) + ["EnchantedTatteredBasilisk", 'UltimateThoughtfulArizonaalligatorlizard', 'FormalWideIberianbarbel', 'CluelessFatCockatoo']
    tournaments = Tournament.select(:tournament_id).to_a
    $stderr.puts "old gfycat count: #{old_gfycats.length}"
    connection = Excon.new "https://api.gfycat.com", persistent: true
    path = '/v1/me/gfycats'
    next_round = JSON.parse connection.get(path: path + '?count=500', headers: {"Authorization" => "Bearer #{access_token}"}).body
    all_gfycats = next_round['gfycats']
    cursor = next_round['cursor']
    until (not cursor) or cursor.empty? do
      next_round = JSON.parse connection.get(path: path + "?count=500&cursor=#{cursor}", headers: {"Authorization" => "Bearer #{access_token}"}).body
      cursor = next_round['cursor']
      all_gfycats = all_gfycats + next_round['gfycats'] if next_round['gfycats']
    end

    new_gfycats = all_gfycats.reject{|a| old_gfycats.include? a['gfyName']}
    $stderr.puts "new gfycats count: #{new_gfycats.length}"
    new_gfycats.each do |gfy|
      if gfy['tags'] and gfy['tags'].join.include? 'tournament'
        tags = Hash[gfy['tags'].map{|x| x.split ": "}]
      else
        next
      end

      left_score = tags['leftscore'] || -1
      right_score = tags['rightscore'] || -1
      if tournaments.include? tags['tournament'] and not tags['tournament'].nil?
        $stderr.puts "#{tags['tournament']} doesn't exist"
        exit(1)
      end
      tournament_id = tags['tournament']
      db.transaction do
        begin
          Gfycat.new(
            gfycat_gfy_id: gfy['gfyName'],
            tournament_id: tournament_id,
            weapon: tags['weapon'],
            gender: tags['gender'],
            created_date: Time.now.to_i,
            fotl_name: tags['leftname'],
            fotr_name: tags['rightname'],
            left_score: left_score,
            right_score: right_score,
            touch: tags['touch']
          ).save

        # puts db[:gfycats].insert_sql(
        #        gfycat_gfy_id: gfy['gfyName'],
        #        tournament_id: tournament_id,
        #        weapon: tags['weapon'],
        #        gender: tags['gender'],
        #        created_date: Time.now.to_i,
        #        fotl_name: tags['leftname'],
        #        fotr_name: tags['rightname'],
        #        left_score: left_score,
        #        right_score: right_score,
        #        touch: tags['touch']
        #      ) + ';'
        rescue => e
          $stderr.puts e.to_s
        end
      end
    end
  end
end
end
