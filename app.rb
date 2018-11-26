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
    @gfycats = get_touches_query_gfycats params
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
  Thread.new do
    next_round = JSON.parse Excon.get('https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500').body
    all_gfycats = next_round['gfycats']
    cursor = next_round['cursor']
    until cursor.empty? do
      next_round = JSON.parse Excon.get("https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500&cursor=#{cursor}").body
      cursor = next_round['cursor']
      all_gfycats = all_gfycats + next_round['gfycats']
    end
    old_gfycats = DB[:gfycats].map(:gfycat_gfy_id)
    new_gfycats = all_gfycats.reject{|a| old_gfycats.include? a['gfyName']}
    new_gfycats.each do |gfy|
      Logger.info "adding #{gfy['gfyName']}"
      if gfy['tags']
        tags = Hash[gfy['tags'].map{|x| x.split ": "}]
      else
        logger.error "#{gfy['gfyName']} missing tags"
        next
      end
      
      begin
        DB[:gfycats].where(gfycat_gfy_id: gfy['gfyName']).update(
          tournament: tags['tournament'],
          weapon: tags['weapon'],
          gender: tags['gender'],
          fotl_name: tags['leftname'],
          fotr_name: tags['rightname'],
          touch: tags['touch']
        )
      rescue Sequel::UniqueConstraintViolation
        logger.error "duplicate gfy id: #{gfy['gfyName']}"
      rescue => e
        logger.info e.to_s 
      end
    end
  end
end

def get_touches_query_gfycats params
  left_query = Bout.join(:fencers, id: :left_fencer_id)
  right_query = Bout.join(:fencers, id: :right_fencer_id)
  
  if params["lastname"] and not params["lastname"].empty?
    left_query = left_query.where(last_name: params["lastname"].upcase)
    right_query = right_query.where(last_name: params["lastname"].upcase)
  end

  if params["firstname"] and not params["firstname"].empty?
    left_query = left_query.where(first_name: params["firstname"].capitalize)
    right_query = right_query.where(first_name: params["firstname"].capitalize)
  end
  if params["tournament"] and params['tournament'] != "all"
    left_query = left_query.where(tournament_id: params["tournament"])
    right_query = right_query.where(tournament_id: params["tournament"])
  end

  #use min because the gfy with the lowest opponent's score is the one they scored on.
  if params['score-fencer'] == 'highest'
    left_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).qualify.join(
      Gfycat.select(:bout_id, :left_score,
                    Sequel.function(:min, :right_score).as(:right_score))
        .qualify.join(
          Gfycat.distinct
            .select(:bout_id, Sequel.function(:max, :left_score).as(:left_score))
            .where(touch: ['left', 'double'], valid: true)
            .group_by(:bout_id)
            .order_by(:left_score), bout_id: :bout_id, left_score: :left_score)
        .where(valid: true)
        .group_by(:bout_id, :left_score).qualify,
      bout_id: :bout_id, left_score: :left_score, right_score: :right_score)
                  .qualify.where(valid: true, touch: ['left', 'double'])

    right_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :right_score, :right_score).qualify.join(
      Gfycat.select(:bout_id, :right_score,
                    Sequel.function(:min, :left_score).as(:left_score))
        .qualify.join(
          Gfycat.distinct
            .select(:bout_id, Sequel.function(:max, :right_score).as(:right_score))
            .where(touch: ['right', 'double'], valid: true)
            .group_by(:bout_id)
            .order_by(:right_score), bout_id: :bout_id, right_score: :right_score)
        .where(valid: true)
        .group_by(:bout_id, :right_score).qualify,
      bout_id: :bout_id, left_score: :left_score, right_score: :right_score)
                   .qualify.where(valid: true, touch: ['right', 'double'])
  elsif params["score-fencer"] and params['score-fencer'] != 'any'
    left_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(left_score: params['score_fencer'].to_i, touch: ['left', 'double'], valid: true)

    right_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(right_score: params['score_fencer'].to_i, touch: ['right', 'double'], valid: true)
  else
    left_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(valid: true, touch: ['left', 'double'])
    right_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :right_score, :right_score).where(valid: true, touch: ['right', 'double'])
  end
  left_query = left_query.join(left_gfys, bout_id: Sequel[:bouts][:id])
  right_query = right_query.join(right_gfys, bout_id: Sequel[:bouts][:id])
  left_query = left_query.distinct.select(:gfycat_gfy_id)
  right_query = right_query.distinct.select(:gfycat_gfy_id)

  logger.info right_query.sql
  gfycat_ids = left_query.map{|a| a[:gfycat_gfy_id]} + right_query.map{|a| a[:gfycat_gfy_id]}
  
  gfycat_ids.sort.uniq
end
