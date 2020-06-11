require 'pry'
require 'json'
class Fencer < Sequel::Model
  def bouts
    Bout.where(left_fencer_id: id).or(right_fencer_id: id)
  end

  def gfycats
    Gfycat.where(left_fencer_id: id).or(right_fencer_id: id)
  end

  def name
    self.last_name.split.map{|a| a.capitalize}.join(" ") + ", " + self.first_name.split.map{|a| a.capitalize}.join(" ")
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
                           Sequel.join([:first_name, :last_name]).ilike(name.gsub(" ", "") + "%")
                        )
    if query.count == 0
      query = query.or(Sequel.join([:last_name, :first_name]).ilike(name[0...-1].gsub(" ", "") + "%"))
      query = query.or(Sequel.join([:last_name, :first_name]).ilike(name[1..-1].gsub(" ", "") + "%"))
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
