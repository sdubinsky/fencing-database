require 'sinatra'
require 'sequel'
require 'psych'
require 'json'
require 'excon'

config = Psych.load_file("./config.yml")
db_config = config['database']
if db_config['db_username'] or db_config['db_password']
  login = "#{db_config['db_username']}:#{db_config['db_password']}@"
else
  login = ''
end
connstr = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
DB = Sequel.connect(connstr)

require './models/init'

configure :development do
  set :show_exceptions, true
end

set :root, File.dirname(__FILE__)

get '/' do
  @score_strip_locations = [:fotl_warning_box, :fotl_half, :middle, :fotr_half, :fotr_warning_box]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  begin
    @gfycat = Gfycat.random_gfycat_id
  rescue RuntimeError
    return "Please seed the DB by sending a GET request to /update_gfycat_list"
  end
  erb :clip_form
end

get '/submit/?' do
  response = FormResponse.create(
    fotl_name: params['fotl-name'],
    fotr_name: params['fotr-name'],
    initiated: params['initiated-action'],
    strip_location: params['strip-location'],
    body_location: params['score-body-select'],
    stats_id: params['gfycat-id'],
    created_date: Time.now.to_i
  )
  response.save
  redirect '/'
end

# post '/submit_gfycats/?' do
#   request.body.rewind
#   payload = JSON.parse request.body.read
#   payload['gfycats'].each do |gfy|
#     begin
#       Gfycat.new(
#         gfycat_gfy_id: gfy['gfycat_id'],
#         tournament: gfy['tournament'],
#         weapon: gfy['weapon'],
#         gender: gfy['gender'],
#         created_date: Time.now.to_i
#       ).save
#     rescue Sequel::UniqueConstraintViolation
#       puts "duplicate gfy id: #{gfy['gfycat_id']}"
#     end
#   end
  
#   status 200
# end

get '/stats/?' do
  @tournaments = ['all'] + Gfycat.tournaments
  @genders = ['male', 'female']
  @total = FormResponse.total
  @location = FormResponse.most_popular_location tournament: params['tournament-filter']
  @most_popular_location = @location[:strip_location] || "unknown part"
  puts @most_popular_location.to_s
  @most_popular_location = @most_popular_location.gsub("fotr", "FOTR").gsub("fotl", "FOTL").gsub("_", " ") 
  @most_hit_location = FormResponse.most_popular_hit tournament: params['tournament-filter']
  @most_popular_hit = @most_hit_location[:body_location]
  @most_popular_hit = @most_popular_hit.gsub("_", " ") or ""
  erb :stats
end

get '/update_gfycat_list/?' do
  Thread.new do
    next_round = JSON.parse Excon.get('https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500').body
    all_gfycats = next_round['gfycats']
    cursor = next_round['cursor']
    until cursor.empty? do
      puts "getting next round"
      next_round = JSON.parse Excon.get("https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500&cursor=#{cursor}").body
      cursor = next_round['cursor']
      puts cursor
      all_gfycats = all_gfycats + next_round['gfycats']
    end
    puts all_gfycats.length
    old_gfycats = DB[:gfycats].map(:gfycat_gfy_id)
    new_gfycats = all_gfycats.reject{|a| old_gfycats.include? a['gfyName']}
    new_gfycats.each do |gfy|
      tags = Hash[gfy['tags'].map{|x| x.split ": "}]
      begin
        Gfycat.new(
          gfycat_gfy_id: gfy['gfyName'],
          tournament: tags['tournament'],
          weapon: tags['weapon'],
          gender: tags['gender'],
          created_date: Time.now.to_i
        ).save
        puts "added new gfycat ID #{gfy['gfyName']}"
      rescue Sequel::UniqueConstraintViolation
        puts "duplicate gfy id: #{gfy['gfyName']}"
      end
    end
  end
  status 200
end

