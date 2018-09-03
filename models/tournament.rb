class Tournament < Sequel::Model
  def fencers
    left_fencers = Gfycat.select(:left_fencer_id).where(tournament_id: tournament_id)
    right_fencers = Gfycat.select(:right_fencer_id).where(tournament_id: tournament_id)
    Fencer.where(id: left_fencers).or(id: right_fencers)
  end
end
