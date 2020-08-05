require 'pry'
require 'json'
class Fencer < Sequel::Model
  many_to_many :tournaments
  def bouts
    Bout.where(left_fencer_id: id).or(right_fencer_id: id)
  end

  def gfycats
    Gfycat.where(left_fencer_id: id).or(right_fencer_id: id)
  end

  def name
    if ['CHN', 'JPN', 'KOR'].include? nationality
      self.last_name.split(/(-|'|\s)/).map{|a| a.capitalize}.join(" ") + " " + self.first_name.split.map{|a| a.capitalize}.join(" ")
    else
      self.first_name.split.map{|a| a.capitalize}.join(" ") + " " + self.last_name.split(/('|-|\s)/).map{|a| a.capitalize}.join(" ")
    end
  end

  #Get right_fencer_id from all bouts where self is the left fencer.
  #Do the same for the other side
  #Get the Fencer model for all those ids
  def opponents tournament_id=nil
    left_query = DB[:bouts].where(left_fencer_id: self.id)
    left_query = left_query.where(tournament_id: tournament_id) if tournament_id
    right_ids = left_query.select(:right_fencer_id)
    right_query = DB[:bouts].where(right_fencer_id: self.id)
    right_query = right_query.where(tournament_id: tournament_id) if tournament_id
    left_ids = left_query.select(:right_fencer_id)
    Fencer.where(Sequel[id: left_ids] | Sequel[id: right_ids])
  end

  #In case of duplicate names, list all possibilities
  def self.find_name_possibilities name, tournament_id
    query = Fencer.where(id: db[:fencers_tournaments].select(:fencers_id).where(tournaments_id: tournament_id)).where(
                           Sequel.join([:last_name, :first_name], ' ').ilike(name + "%") |
                           Sequel.join([:last_name, :first_name]).ilike(name.gsub(" ", "") + "%") |
                           Sequel.join([:first_name, :last_name], ' ').ilike(name) |
                           Sequel.join([:first_name, :last_name]).ilike(name.gsub(" ", "") + "%") |
                           (Sequel.function(:levenshtein, name.gsub(" ", ""), Sequel.join([:first_name, :last_name])) < 3) |
                           (Sequel.function(:levenshtein, name.gsub(" ", ""), Sequel.join([:last_name, :first_name])) < 3) |
                           (Sequel.function(:levenshtein, name, :last_name) < 3)
                        )
    if query.count == 0
      query = query.or(Sequel.join([:last_name, :first_name]).ilike(name[0...-1].gsub(" ", "") + "%"))
      query = query.or(Sequel.join([:last_name, :first_name]).ilike(name[1..-1].gsub(" ", "") + "%"))
    end
    query
  end

  def self.search_with_params params
    query = Fencer
    if params["lastname"] and not params["lastname"].empty?
      query = query.where(last_name: params["lastname"].upcase)
    end

    if params["firstname"] and not params["firstname"].empty?
      query = query.where(first_name: params["firstname"].capitalize)
    end

    if params["weapon"] and params['weapon'] != "all"
      query = query.where(weapon: params["weapon"])
    end

    if params['country'] and params['country'] != 'all'
      query = query.where(nationality: params['country'])  
    end
    
    if params['gender'] and params['gender'] != 'all'
      query = query.where(gender: params['gender'])  
    end

    query
  end

  def as_dict
    {
      id: id,
      last_name: last_name,
      first_name: first_name,
      nationality: nationality,
      gender: gender,
      birthdate: birthday,
      weapon: weapon,
      bouts: bouts.map{|a| a.id},
      gfycats: gfycats.map{|a| a.gfycat_gfy_id}
    }
  end

  def to_json
    as_dict.to_json
  end

  def self.json
    fencers = Fencer.all.map{|a| a.as_dict}
    puts fencers.length
    {
      count: fencers.length,
      fencers: fencers
    }.to_json
  end
end
