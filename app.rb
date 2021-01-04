require 'sinatra'
require 'sequel'
require 'psych'
require 'json'
require 'excon'
require 'logger'
require 'bcrypt'
require 'securerandom'
require 'digest/sha2'

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
DB.extension(:pagination)
require './models/init'

require './helpers'
include Helpers
logger = Logger.new($stdout)

use Rack::Session::Cookie, key: 'rack.session', path: '/'
                           

configure :development do
  set :show_exceptions, true
  set :session_secret, File.read("session_secret.txt")
  logger.level = Logger::DEBUG
end

set :root, File.dirname(__FILE__)
'''
TODO:
1. Download all gfys, update their names.
2. Save that code along with the heidenheim code
'''

before do
  body = request.body.read
    View.create(
    endpoint: env['REQUEST_PATH'],
    http_method: env['REQUEST_METHOD'],
    form_data: body.empty? ? params.to_json : body,
    country_code: env['HTTP_CF_IPCOUNTRY'],
    viewer_ip: env['HTTP_CF_CONNECTING_IP'],
    created_at: Time.now.to_i
  )
  @request.body.rewind
end

get '/' do
  redirect '/stats'
end

get '/search/?' do
  @tournaments = Tournament.order_by(:tournament_name)
  if params
    @fencers = []
    params['page'] = 1 unless params['page']
    @gfycats = Helpers.get_touches_query_gfycats(DB, params).map{|gfy| gfy[:gfycat_gfy_id]}
    @get_string = params.map do |k, v|
      if k == 'page'
        next
      end
      "#{k}=#{v}"
    end.compact.join "&"
    erb :search
  else 
    @gfycats = []
    @fencers = []
    @partial_title = "fencers"
    erb :search
  end
end

post '/search' do
  @tournaments = Tournament.order_by(:tournament_name)
  if params['submit-search'] == 'Search Fencers'
    @gfycats = []
    @fencers = Fencer.search_with_params params
  else
    @fencers = []
    params['page'] = 1 unless params['page']
    @gfycats = Helpers.get_touches_query_gfycats(DB, params).map{|gfy| gfy[:gfycat_gfy_id]}
    @get_string = params.map do |k, v|
      if k == 'page'
        next
      end
      "#{k}=#{v}"
    end.compact.join "&"
  end
  erb :search
end

get '/clip/:gfycat_gfy_id/?' do 
  @score_strip_locations = [:fotl_warning_box, :fotl_half, :middle, :fotr_half, :fotr_warning_box]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  begin
    @gfycat = Gfycat.first(gfycat_gfy_id: params['gfycat_gfy_id'])
    redirect "/clip/" unless @gfycat
    logger.info "Showing #{@gfycat.gfycat_gfy_id}"
  rescue RuntimeError
    return "Please seed the DB by sending a GET request to /update_gfycat_list"
  end
  erb :clip
end

get '/clip/?' do
  @gfycat = Gfycat.random_gfycat_id
  redirect "/clip/#{@gfycat.gfycat_gfy_id}"
end

post '/clip/submit/?' do
  response = FormResponse.create(
    initiated: params['initiated-action'],
    strip_location: params['strip-location'],
    body_location: params['score-body-select'],
    stats_id: params['gfycat-id'],
    created_date: Time.now.to_i,
    user_id: session[:user_id]
  )

  logger.info("new submission: #{response.to_s}")
  redirect "/clip/=#{params['gfycat-id']}"
end

get '/stats/?' do
  @tournaments = Tournament.order_by(:tournament_year).all
  
  @genders = ['male', 'female']
  @total = FormResponse.total tournament: params['tournament-filter'], fencer_name: params['fencer-filter'], gender: params['gender-filter'], weapon: params['weapon-filter']
  @location = FormResponse.most_popular_location tournament: params['tournament-filter']
  @most_popular_location = @location[:strip_location]
  @most_popular_location = @most_popular_location.gsub("fotr", "FOTR").gsub("fotl", "FOTL").gsub("_", " ") 
  @most_hit_location = FormResponse.most_popular_hit tournament: params['tournament-filter']
  @most_popular_hit = @most_hit_location[:body_location]
  @most_popular_hit = @most_popular_hit.gsub("_", " ") or ""

  if logged_in?
    @current_user_responses = current_user.form_responses.count
  end
  
  query = FormResponse.build_query tournament: params['tournament-filter'], fencer_name: params['fencer-filter'], weapon: params['weapon-filter']
  @color_map = FormResponse.heatmap_colors query
  @fencer_names = ['all'] + Gfycat.fencer_names
  erb :stats
end

get '/fencers/?:fie_id' do
  @fencer = Fencer.first(fie_id: params['fie_id'])
  query = Gfycat.join(:form_responses, stats_id: :gfycat_gfy_id).where(Sequel.|(left_fencer_id: @fencer.id, right_fencer_id: @fencer.id))
  @left_touches = Gfycat.where(left_fencer_id: @fencer.id, touch: 'left').exclude(right_fencer_id: nil)
  @right_touches = Gfycat.where(right_fencer_id: @fencer.id, touch: 'right').exclude(left_fencer_id: nil)

  left_received = Gfycat.where(left_fencer_id: @fencer.id, touch: 'right').exclude(right_fencer_id: nil)
  right_received = Gfycat.where(right_fencer_id: @fencer.id, touch: 'left').exclude(left_fencer_id: nil)
  
  received_by_opponent = left_received.select(:right_fencer_id).union(right_received.select(:left_fencer_id), all: true).group_and_count(:right_fencer_id)
  form_responses = FormResponse.where(stats_id: @left_touches.select(:gfycat_gfy_id)).or(stats_id: @right_touches.select(:gfycat_gfy_id))

  @touches_by_opponent = @left_touches.select(:right_fencer_id).union(@right_touches.select(:left_fencer_id), all: true).group_and_count(:right_fencer_id)

  @fencers = Bout.select(:left_fencer_id).where(right_fencer_id: @fencer.id).union(Bout.select(:right_fencer_id).where(left_fencer_id: @fencer.id), all: true).group_and_count(:left_fencer_id).reverse.from_self(alias: :opponents)

  @fencers = @fencers.select(Sequel[:received][:count].as(:touches_received), Sequel[:touches][:count].as(:touches_scored), :left_fencer_id, Sequel[:opponents][:count].as(:bouts)).join(@touches_by_opponent.as(:touches), right_fencer_id: :left_fencer_id).join(received_by_opponent.as(:received), Sequel[:received][:right_fencer_id] => Sequel[:touches][:right_fencer_id]).from_self

  @fencers = @fencers.select(:last_name, :first_name, :fie_id, :touches_scored, :touches_received, :bouts, :nationality).join(DB[:fencers], id: :left_fencer_id).order(:bouts)
  @partial_title = "opponents"
  @location = form_responses.group_and_count(:body_location).reverse(:count).first
  @location = @location ? @location.body_location : 'unknown'
  @color_map = FormResponse.heatmap_colors query
  erb :fencer
end

post '/error_report' do
  body = JSON.parse(@request.body.read)
  gfy_id = body['gfy_id']
  ErrorReport.create(
    gfycat_gfy_id: gfy_id,
    created_date: Time.now.to_i
  )
end

get '/signup/?' do
  erb :signup
end

post '/signup/?' do
  if not params['signup-username'] and params['signup-password']
    @error_message = "Please add a username and password"
    erb :signup
  else
    begin
      user = User.create(
        username: params['signup-username'],
        password_hash: BCrypt::Password.create(params['signup-password']),
        email: params['signup-email'],
        created_date: Time.now.to_i
      )
    rescue Sequel::UniqueConstraintViolation
      @error_message = "username already taken."
    erb :signup
    else
      session[:user_id] = user.id
      redirect '/'
    end
  end
end

get '/login/?' do
  erb :login
end

get '/logout/?' do
  session.delete :user_id
  redirect '/'
end

post '/check_login/?' do
  username = params['login-username']
  user = User.first(username: username)
  if not user
    redirect '/'
  end
  begin
    password = BCrypt::Password.new user.password_hash
  rescue BCrypt::Errors::InvalidHash
    @error_message = "Error: Invalid password"
    logger.info "failed to log in user #{params['username']}"
    return erb :login
  end

  if password == params['login-password']
    session[:user_id] = user.id
  end
  redirect params['url']  if params['url']
  redirect '/'
end

get '/reels/?' do
  login_check
  @in_progress_reels = current_user.highlight_reels.select{|a| !a.completed}
  @completed_reels = current_user.highlight_reels.select{|a| a.completed}
  erb :reels
end

get '/reels/new/?' do
  login_check
  @fencers = Fencer.select(:id, Sequel.lit("(last_name || ' ' || first_name) as full_name")).order_by(:full_name)
  @nationalities = Fencer.select(:nationality).distinct.order_by(:nationality).all.map{|a| a.nationality}
  @tournaments = Tournament.order_by(:tournament_name)
  erb :new_reel
end

post '/reels/create' do
  logger.info "creating new reel for user #{@current_user&.username}"
  login_check
  params['page'] = -1
  gfycats = Helpers.get_touches_query_gfycats DB, params
  reel = HighlightReel.create(
    author: params['author'],
    title: params['title'],
    last_name: params['lastname'],
    first_name: params['firstname'],
    filter_params: params.to_json,
    tournament: params['tournament'],
    user_id: current_user.id
  )
  reel.save
  params['page'] = -1
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


get '/reels/help/?' do
  erb :reel_help
end

get '/reels/:id/?' do
  reel_owner_check params['id']
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
  reel_owner_check params['id']
  @clip = ReelClip.where(selected: nil, highlight_reel_id: params['id']).order_by(Sequel.lit('random()')).first
  @clip_count = ReelClip.where(selected: true, highlight_reel_id: params['id']).count
  unless @clip
    redirect to("/reels/#{params['id']}")
  end
  erb :reel_clip
end

get '/reels/:id/export/?' do
  reel_owner_check params['id']
  @reel = HighlightReel[params['id']]
  @reel.update(completed: true)
  @reel.export_reel
end

get '/reels/:id/upload/?' do
  reel_owner_check params['id']
  @reel = HighlightReel[params['id']]
  @reel.update(completed: true, ready_for_upload: true)
  redirect '/reels'
end

get '/reels/:id/newround' do
  reel_owner_check params['id']
  @reel = HighlightReel[params['id']]
  DB.transaction do
    ReelClip.where(selected: nil, highlight_reel_id: params['id']).each do |clip|
      clip.selected = false
      clip.save
    end
  end
  DB.transaction do
    ReelClip.where(selected: true, highlight_reel_id: params['id']).each do |clip|
      clip.round = @reel.round
      clip.selected = nil
      clip.save
    end
    @reel.round += 1
    @reel.save
  end
  redirect to("/reels/#{params['id']}/")
end

post '/reels/submit/?' do
  body = JSON.parse(@request.body.read)
  reel_owner_check body['reelId']
  @clip = ReelClip.first(selected: nil, highlight_reel_id: body['reelId'], gfycat_gfy_id: body['clipId'])

  case body['result']
  when 'accept'
    @clip.selected = true
  when 'reject'
    @clip.selected = false
  end
  @clip.save
end

post '/fencing-ai/submit/?' do
  
end

get '/fencing-ai/keycodes/?' do
  FencingAiKeycodes.select(:keycode, :meaning).map{|a| a.to_hash}.to_json
end

get '/fencing-ai/error/?' do
  "Oops"
end

get '/fencing-ai/clip/?' do
  @clip = ReelClip.where(selected: nil, highlight_reel_id: 21).order_by(Sequel.lit('random()')).first
  @keycodes = FencingAiKeycodes.order(:keycode).all
  erb :fencing_ai_clip
end

get '/docs/?' do
  erb :docs
end

get '/api/help/?' do
  erb :help
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

get '/api/fencers/?:fie_id' do
  fencer = Fencer.first(fie_id: params['fie_id'])
  return fencer.to_json if fencer
  status 404
  return "fencer not found"
end

get '/api/clips/questions/?:weapon?/?' do
  unless params['weapon']
    status 400
    {error_message: "Error: Please specify a weapon"}.to_json
  else
    FormResponse.questions(params['weapon']).to_json
  end
end

get '/api/clips/random/?:weapon?/?' do
  gfy = Gfycat.random_gfycat_id params['weapon']
  return gfy.to_json
end

get '/api/clips/:gfycat_gfy_id/?' do
  if params["gfycat_gfy_id"]
    gfy = Gfycat.first(gfycat_gfy_id: params["gfycat_gfy_id"])
    return gfy.to_json if gfy and gfy.valid
    status 404
    return "gfycat not found"
  end
end

post '/api/clips/submit/?' do
  #To generate an API key:
  # key = SecureRandom.base64(16) # send this to the user
  # key_hash = Digest::SHA2.new << user.password_hash
  api_key = env['HTTP_X_AUTHENTICATION_HEADER']
  key_hash = Digest::SHA2.new << api_key
  api_key = ApiKey.first(key: key_hash.to_s)
  
  if not api_key
    status 401
    return    
  end
  request.body.rewind
  body = JSON.parse request.body.read

  user = api_key.user

  if not body['gfycat-id']
    status 400
    return {"error_message" => "Error: Missing key #{key}"}.to_json
  end
  
  response = FormResponse.create(
    initiated: body['initiated-action'],
    strip_location: body['strip-location'],
    body_location: body['score-body-select'],
    stats_id: body['gfycat-id'],
    created_date: Time.now.to_i,
    user_id: user.id
  )

  logger.info("new submission: #{response.to_s}")
end
