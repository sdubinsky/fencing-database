require 'sinatra'
require 'sequel'
require 'psych'
require 'json'
require 'excon'
require 'logger'

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
    params['page'] = 1 unless params['page']
    @gfycats = Helpers.get_touches_query_gfycats(DB, params).map{|gfy| gfy[:gfycat_gfy_id]}
    @get_string = params.map do |k, v|
      if k == 'page'
        next
      end
      "#{k}=#{v}"
    end.compact.join "&"
  else
    @gfycats = []
  end

  @fencers = Fencer.select(:id, Sequel.lit("(last_name || ' ' || first_name) as full_name")).order_by(:full_name)
  @nationalities = Fencer.select(:nationality).distinct.order_by(:nationality).all.map{|a| a.nationality}
  @tournaments = Tournament.order_by(:tournament_name)
  erb :touches
end

get '/reels/?' do
  @reels = HighlightReel.all
  erb :reels
end

get '/reels/new/?' do
  @fencers = Fencer.select(:id, Sequel.lit("(last_name || ' ' || first_name) as full_name")).order_by(:full_name)
  @nationalities = Fencer.select(:nationality).distinct.order_by(:nationality).all.map{|a| a.nationality}
  @tournaments = Tournament.order_by(:tournament_name)
  erb :new_reel
end

post '/reels/create' do
  reel = HighlightReel.create(
    author: params['author'],
    title: params['title'],
    last_name: params['last_name'],
    first_name: params['first_name'],
    tournament: params['tournament']
  )
  reel.save
  params['page'] = -1
  gfycats = Helpers.get_touches_query_gfycats DB, params
  DB.transaction do
    gfycats.each do |gfy|
      ReelClip.create(
        gfycat_gfy_id: gfy[:gfycat_gfy_id],
        highlight_reel: reel,
      )
    end
  end
  redirect "/reels/#{reel.id}"
end

get '/reels/:id/?' do
  @reel = HighlightReel[params['id']]
  @clip_count = ReelClip.where(selected: true, highlight_reel_id: @reel.id).count
  @seconds = @clip_count * 10
  @hours = @seconds / 3600
  @seconds = @seconds % 3600
  @minutes = @seconds / 60
  @seconds = @seconds % 60
  @unsorted_clip_count = ReelClip.where(selected: nil, highlight_reel_id: @reel.id).count
  erb :reel
end

get '/reels/:id/judge/?' do
  @clip = ReelClip.where(selected: nil, highlight_reel_id: params['id']).order_by(Sequel.lit('random()')).first
  @clip_count = ReelClip.where(selected: true, highlight_reel_id: params['id']).count
  unless @clip
    redirect to("/reels/#{params['id']}")
  end
  erb :reel_clip
end

get '/reels/:id/export' do
  @reel = HighlightReel[params['id']]
  @reel.export_reel
end

get '/reels/:id/newround' do
  @reel = HighlightReel[params['id']]
  DB.transaction do
    ReelClip.where(selected: nil, highlight_reel_id: params['id']).each do |clip|
      clip.selected = false
      clip.save
    end
  end
  DB.transaction do
    ReelClip.where(selected: true, highlight_reel_id: params['id']).each do |clip|
      clip.selected = nil
      clip.save
    end
  end
  redirect to("/reels/#{params['id']}/")
end

post '/reels/submit/?' do
  body = JSON.parse(@request.body.read)
  @clip = ReelClip.first(selected: nil, highlight_reel_id: body['reelId'], gfycat_gfy_id: body['clipId'])

  case body['result']
  when 'accept'
    @clip.selected = true
  when 'reject'
    @clip.selected = false
  end
  @clip.save
end

get '/update_gfycat_list/?' do
  Gfycat.update_gfycat_list
  logger.debug 'done with gfycats'
  status 200
end

get '/fix_gfycat_tags/?' do
  Helpers.fix_gfycat_tags DB, params
end

get '/api/bouts/?:id_number?' do
  if params["id_number"]
    bout = Bout[params["id_number"].to_i]
    return bout.to_json if bout
    status 404
    return "bout not found"
  else
    Bout.json
  end
end

get '/api/tournaments/?:name?' do
  if params["name"]
    tournament = Tournament.first(tournament_id: params["name"])
    return tournament.to_json if tournament
    status 404
    return "tournament not found"
  else
    Tournament.json
  end
end

get '/api/fencers/?:id?' do
  if params["id"]
    fencer = Fencer[params["id"].to_i]
    return fencer.to_json if fencer
    status 404
    return "fencer not found"
  else
    Fencer.json
  end
end

get '/api/gfycats/?:gfycat_gfy_id?' do
  if params["gfycat_gfy_id"]
    gfy = Gfycat.first(gfycat_gfy_id: params["gfycat_gfy_id"])
    return gfy.to_json if gfy
    status 404
    return "gfycat not found"
  end
end
