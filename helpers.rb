require 'pry'
require 'json'
require 'excon'
require 'logger'
require 'sequel'
#real helpers at the bottom - the rest are just some methods from app.rb that didn't fit there.
module Helpers
  def self.fix_gfycat_tags db, params
    logger = Logger.new($stdout)
    Thread.new do
      next_round = JSON.parse Excon.get('https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500').body
      all_gfycats = next_round['gfycats']
      cursor = next_round['cursor']
      until cursor.empty? do
        next_round = JSON.parse Excon.get("https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500&cursor=#{cursor}").body
        cursor = next_round['cursor']
        all_gfycats = all_gfycats + next_round['gfycats']
      end
      old_gfycats = db[:gfycats].map(:gfycat_gfy_id)
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
          db[:gfycats].where(gfycat_gfy_id: gfy['gfyName']).update(
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

  def self.get_touches_query_gfycats db, params
    logger = Logger.new($stdout)
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
    
    if params['year'] and params['year'] != 'all'
      tournaments = Tournament.select(:tournament_id).where(tournament_year: params['year'])
      left_query = left_query.where(tournament_id: tournaments)
      right_query = right_query.where(tournament_id: tournaments)
    end

    if params['weapon'] and params['weapon'] != 'all'
      left_query = left_query.where(weapon: params["weapon"])
      right_query = right_query.where(weapon: params["weapon"])      
    end

    if params['gender'] and params['gender'] != 'all' 
      left_query = left_query.where(gender: params["gender"])
      right_query = right_query.where(gender: params["gender"])
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
    elsif params["score-fencer"] and params['score-fencer'] != 'all'
      left_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(left_score: params['score-fencer'].to_i, touch: ['left', 'double'], valid: true)

      right_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(right_score: params['score-fencer'].to_i, touch: ['right', 'double'], valid: true)
    else
      left_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :left_score, :right_score).where(valid: true, touch: ['left', 'double'])
      right_gfys = Gfycat.select(:gfycat_gfy_id, :bout_id, :right_score, :right_score).where(valid: true, touch: ['right', 'double'])
    end
    left_query = left_query.join(left_gfys, bout_id: Sequel[:bouts][:id])
    right_query = right_query.join(right_gfys, bout_id: Sequel[:bouts][:id])
    left_query = left_query.distinct.select(:gfycat_gfy_id)
    right_query = right_query.distinct.select(:gfycat_gfy_id)

    final_query = left_query.union(right_query)
    unless params["page"] and params["page"].to_i == -1
      page = (params["page"] || 1).to_i
      final_query = final_query.paginate(page, 10)
    end
    logger.info final_query.sql
    final_query
  end
end


helpers do
  def logged_in?
    !!session[:user_id]
  end

  def login_check
    if not logged_in?
      redirect "/login?url=#{request.path_info}"
    end
  end

  def current_user
    @current_user ||= User.first(id: session[:user_id])
  end

  def reel_owner_check reel_id
    login_check
    unless current_user.highlight_reels.map{|reel| reel[:id]}.include? reel_id.to_i
      redirect "/"
    end
  end
end
