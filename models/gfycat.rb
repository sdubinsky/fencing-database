require 'logger'
require 'excon'
class Gfycat < Sequel::Model
  one_to_many :form_responses
  def self.random_gfycat_id
    gfycat = Gfycat.all.sample
    raise RuntimeError.new("no gfycats found") if not gfycat
    gfycat
  end
  def self.tournaments
    tournaments = Gfycat.select(:tournament).distinct.map{|t| t[:tournament]}
    tournaments
  end
  def self.fencer_names 
    fencer_names = Gfycat.select(:fotl_name).all
    fencer_names = fencer_names + Gfycat.select(:fotr_name).all
    fencer_names.map!{|a| a[:fotl_name].to_s}
    fencer_names.uniq!
    fencer_names.sort
  end

  def self.update_gfycat_list
    logger = Logger.new $stdout
    next_round = JSON.parse Excon.get('https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500').body
    all_gfycats = next_round['gfycats']
    cursor = next_round['cursor']
    puts all_gfycats.count
    until cursor.empty? do
      next_round = JSON.parse Excon.get("https://api.gfycat.com/v1/users/fencingdatabase/gfycats?count=500&cursor=#{cursor}").body
      cursor = next_round['cursor']
      all_gfycats = all_gfycats + next_round['gfycats']
    end
    old_gfycats = Gfycat.map(:gfycat_gfy_id)
    new_gfycats = all_gfycats.reject{|a| old_gfycats.include? a['gfyName']}
    new_gfycats.each do |gfy|
      logger.info "adding #{gfy['gfyName']}"
      if gfy['tags']
        tags = Hash[gfy['tags'].map{|x| x.split ": "}]
      else
        logger.error "#{gfy['gfyName']} missing tags"
        next
      end

      left_score = tags['leftscore'] || -1
      right_score = tags['rightscore'] || -1
      begin
        Gfycat.new(
          gfycat_gfy_id: gfy['gfyName'],
          tournament: tags['tournament'],
          weapon: tags['weapon'],
          gender: tags['gender'],
          created_date: Time.now.to_i,
          fotl_name: tags['leftname'],
          fotr_name: tags['rightname'],
          left_score: tags['leftscore'],
          right_score: tags['rightscore'],
          touch: tags['touch']
        ).save
        logger.info "added new gfycat ID #{gfy['gfyName']}"
      rescue Sequel::UniqueConstraintViolation
        logger.error "duplicate gfy id: #{gfy['gfyName']}"
      rescue => e
        logger.info e.to_s
      end
    end
  end
end
