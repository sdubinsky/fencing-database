require 'json'
require 'excon'
require 'sequel'
require 'psych'

if ENV['DATABASE_URL']
  connstr = ENV['DATABASE_URL']
else
  config = Psych.load_file("./config.yml")
  db_config = config['database']
  if db_config['db_username'] or db_config['db_password']
    login = "#{db_config['db_username']}:#{db_config['db_password']}@"
  else
    login = ''
  end
  connstr = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
end
DB = Sequel.connect connstr
require './models/init'

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

access_token = get_access_token

#the list is just gfys that keep getting included for some reason
old_gfycats = Gfycat.select(:gfycat_gfy_id).order(:gfycat_gfy_id).all
extra_gfys = ["EnchantedTatteredBasilisk", 'UltimateThoughtfulArizonaalligatorlizard', 'FormalWideIberianbarbel', 'CluelessFatCockatoo']
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

new_gfycats = all_gfycats.reject{|a| extra_gfys.include?(a) || old_gfycats.bsearch{|b| a['gfyName'] <=> b }}

$stderr.puts "new gfycats count: #{new_gfycats.length}"
DB = Sequel.connect connstr
require './models/init'
DB.transaction do
  new_gfycats.each do |gfy|
    if gfy['tags'] and gfy['tags'].join.downcase.include? 'tournament'
      tags = Hash[gfy['tags'].map{|x| x.downcase.split ": "}]
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
    begin
      DB[:gfycats].insert(
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
      )
    rescue => e
      $stderr.puts e.to_s
      exit 1
    end
  end
end
