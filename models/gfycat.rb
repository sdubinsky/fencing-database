require 'pry'
require 'logger'
require 'excon'
class Gfycat < Sequel::Model
  one_to_many :form_responses
  many_to_one :bout
  many_to_one :tournament, key: :tournament_id, primary_key: :tournament_id
  def self.random_gfycat_id weapon = nil
    gfycat = Gfycat.where(Sequel.~(Sequel.or(left_fencer_id: nil, right_fencer_id: nil)))
    if weapon
      gfycat = gfycat.where(weapon: weapon)      
    end
    gfycat = gfycat.order_by(Sequel.function(:random)).first
    raise RuntimeError.new("no gfycats found") if not gfycat
    gfycat
  end

  def self.fencer_names 
    fencer_names = Gfycat.select(:fotl_name).all
    fencer_names = fencer_names + Gfycat.select(:fotr_name).all
    fencer_names.map!{|a| a[:fotl_name].to_s}
    fencer_names.uniq!
    fencer_names.sort
  end

  def self.unassigned_gfys
    Gfycat.where(bout_id: nil).
      exclude(left_fencer_id: nil, right_fencer_id: nil).
      exclude(Sequel.&(Sequel.~(left_fencer_id: nil), Sequel.~(right_fencer_id: nil)))
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
    #EnchantedTatteredBasilisk is just a random gfy that keeps getting mixed in, I don't know why
    old_gfycats = Gfycat.map(:gfycat_gfy_id) << "EnchantedTatteredBasilisk"
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
      tournament = Tournament.first(tournament_id: tags['tournament'])
      if tournament.nil? and not tags['tournament'].nil?
        logger.error "#{tags['tournament']} doesn't exist"
        exit(1)
      end
      tournament_id = tournament ? tournament.tournament_id : nil
      DB.transaction do
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
          logger.info "added new gfycat ID #{gfy['gfyName']}"
        rescue Sequel::UniqueConstraintViolation
          logger.error "duplicate gfy id: #{gfy['gfyName']}"
        rescue => e
          logger.info e.to_s
        end
      end
    end      
  end

  def to_s
    begin
    left_fencer = Fencer[left_fencer_id]
    right_fencer = Fencer[right_fencer_id]
    "#{left_fencer.name} vs. #{right_fencer.name}"
    rescue NoMethodError
      "#{fotl_name} vs. #{fotr_name}"
    end
  end

  def to_s_links
    normalize_names
    begin 
    left_fencer = Fencer[left_fencer_id]
    right_fencer = Fencer[right_fencer_id]
    "<a href=\"/fencers/#{left_fencer.fie_id}\" >#{left_fencer.name}</a> vs. <a href=\"/fencers/#{right_fencer.fie_id}\" >#{right_fencer.name}</a>"
    rescue NoMethodError
      to_s
    end
  end

  def to_dict
    left_fencer = Fencer[left_fencer_id]
    right_fencer = Fencer[right_fencer_id]
    {
      gfycat_gfy_id: gfycat_gfy_id,
      tournament_id: tournament_id,
      weapon: weapon,
      gender: gender,
      fotl_name: left_fencer.name,
      fotr_name: right_fencer.name,
      left_score: left_score,
      right_score: right_score,
      touch: touch
    }
  end

  def to_json
    to_dict.to_json
  end

  def normalize_names
    begin
      if CanonicalName.where(gfy_name: fotr_name).count == 1
        name = CanonicalName.first(gfy_name: fotr_name).canonical_name
      else
        name = fotr_name
      end
      right_name = Fencer.find_name_possibilities(name, tournament.id)
      if right_name.count == 1
        update(
          right_fencer_id: right_name.first.id
        )
      end

      if CanonicalName.where(gfy_name: fotl_name).count == 1
        name = CanonicalName.first(gfy_name: fotl_name).canonical_name
      else
        name = fotl_name
      end
      left_name = Fencer.find_name_possibilities(name, tournament.id)

      if left_name.count == 1
        update(
          left_fencer_id: left_name.first.id
        )
      end
    rescue => e
      puts "problem with gfy: #{gfycat_gfy_id}"
    end
  end
end
