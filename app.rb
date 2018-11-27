require 'sinatra'
require 'sequel'
require 'psych'
require 'json'
require 'excon'
require 'logger'

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
Sequel::Model.db.extension(:pagination)

require './helpers'
include Helpers
logger = Logger.new($stdout)

configure :development do
  set :show_exceptions, true
  logger.level = Logger::DEBUG
end

set :root, File.dirname(__FILE__)
'''
TODO:
1. Download all gfys, update their names.
2. Save that code along with the heidenheim code
3. Make sure that the fencer filter accounts for who scores the touch
'''

get '/' do 
  @score_strip_locations = [:fotl_warning_box, :fotl_half, :middle, :fotr_half, :fotr_warning_box]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  begin
    @gfycat = Gfycat.random_gfycat_id
    logger.info "Showing #{@gfycat.gfycat_gfy_id}"
  rescue RuntimeError
    return "Please seed the DB by sending a GET request to /update_gfycat_list"
  end
  erb :clip_form
end

get '/submit/?' do
  response = FormResponse.create(
    initiated: params['initiated-action'],
    strip_location: params['strip-location'],
    body_location: params['score-body-select'],
    stats_id: params['gfycat-id'],
    created_date: Time.now.to_i
  )
  response.save
  logger.info("new submission: #{response.to_s}")
  redirect '/'
end

get '/stats/?' do
  @tournaments = Tournament.all
  
  @genders = ['male', 'female']
  @total = FormResponse.total tournament: params['tournament-filter'], fencer_name: params['fencer-filter']
  @location = FormResponse.most_popular_location tournament: params['tournament-filter']
  @most_popular_location = @location[:strip_location]
  @most_popular_location = @most_popular_location.gsub("fotr", "FOTR").gsub("fotl", "FOTL").gsub("_", " ") 
  @most_hit_location = FormResponse.most_popular_hit tournament: params['tournament-filter']
  @most_popular_hit = @most_hit_location[:body_location]
  @most_popular_hit = @most_popular_hit.gsub("_", " ") or ""
  @color_map = FormResponse.heatmap_colors tournament: params['tournament-filter'], fencer_name: params['fencer-filter']
  @fencer_names = ['all'] + Gfycat.fencer_names
  erb :stats
end

get '/touches/?' do
  unless params.empty?
    @gfycats = Helpers.get_touches_query_gfycats DB, params
  else
    @gfycats = []
  end
  @fencers = Fencer.select(:id, Sequel.lit("(last_name || ' ' || first_name) as full_name")).order_by(:full_name)
  @nationalities = Fencer.select(:nationality).distinct.order_by(:nationality).all.map{|a| a.nationality}
  @tournaments = Tournament
  erb :touches
end

get '/update_gfycat_list/?' do
  Gfycat.update_gfycat_list
  logger.debug 'done with gfycats'
  status 200
end

get '/fix_gfycat_tags/?' do
  Helpers.fix_gfycat_tags DB, params
end

  
end
