require 'pry'
class Fencer < Sequel::Model
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
end
