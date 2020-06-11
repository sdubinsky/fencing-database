require 'json'

class Tournament < Sequel::Model
  one_to_many :bouts, key: :tournament_id, primary_key: :tournament_id
  many_to_many :fencers
  def fencers
    left_fencers = Gfycat.select(:left_fencer_id).where(tournament_id: tournament_id)
    right_fencers = Gfycat.select(:right_fencer_id).where(tournament_id: tournament_id)
    Fencer.where(id: left_fencers).or(id: right_fencers)
  end

  def as_dict
    {
      id: id,
      short_name: tournament_id,
      name: tournament_name,
      bouts: bouts.map{|b| b.id},
      year: tournament_year        
    }
  end

  def to_json
    as_dict.to_json
  end
  
  def self.json
    tournaments = Tournament.all.map{|tournament| tournament.as_dict}
    {
      count: tournaments.length,
      tournaments: tournaments
    }.to_json
  end
end
