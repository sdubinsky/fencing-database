require 'logger'
require 'excon'
class Gfycat < Sequel::Model
  one_to_many :form_responses
  many_to_one :tournament, key: :tournament_id, primary_key: :tournament_id
  def self.random_gfycat_id
    gfycat = Gfycat.all.sample
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
    old_gfycats = Gfycat.map(:gfycat_gfy_id) + "EnchantedTatteredBasilisk"
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
          tournament_id: Tournament.first(tournament_id: tags['tournament']),
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
        normalize_names
      rescue Sequel::UniqueConstraintViolation
        logger.error "duplicate gfy id: #{gfy['gfyName']}"
      rescue => e
        logger.info e.to_s
      end
    end
  end

  def normalize_names
    def check_names gfy_name
      #Finds matches where:
      #1. The only name available is the last name, and it has exactly one match
      #2. There's a last name and some of the first name, and it has exactly one match
      #3. There's a last name, and some of the first name, and only the last name matches
      #4. All of the above, except the first name is multipart not the last name

      
      names1 = Fencer.where(last_name: gfy_name)
      return names1.first if names1 and names1.count == 1
      names2 = Fencer.where(last_name: gfy_name.split(" ")[0...-1], first_name: /^#{gfy_name.split(" ")[-1]}/i)
      return names2.first if names2 and names2.count == 1
      names3 = Fencer.where(last_name: gfy_name.split(" ")[0...-1])
      return names3.first if names3 and names3.count == 1

      names4 = Fencer.where(last_name: gfy_name.split(" ")[0...2], first_name: /^#{gfy_name.split(" ")[2..-1]}/i)
      return names4.first if names4 and names4.count == 1
      names5 = Fencer.where(last_name: gfy_name.split(" ")[0...2])
      return names5.first if names5 and names5.count == 1
    end
    
    right_name = check_names fotr_name
    if right_name
      update(
        right_fencer_id: right_name.id
      )
    end

    left_name = check_names fotl_name
    if left_name
      update(
        left_fencer_id: left_name.id
      )
    end
  end
end
