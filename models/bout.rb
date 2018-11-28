require 'json'
class Bout < Sequel::Model
  one_to_many :gfycats
  many_to_one :tournament, key: :tournament_id, primary_key: :tournament_id
  one_to_one :left_fencer, primary_key: :left_fencer_id, key: :id, class: :Fencer
  one_to_one :right_fencer, primary_key: :right_fencer_id, key: :id, class: :Fencer
  def final_touch
    left_final = gfycats_dataset.order_by(:left_score).reverse.limit(1)
    right_final = gfycats_dataset.order_by(:left_score).reverse.limit(1)
    if left_final.first.left_score < right_final.first.right_score
      return left_final
    else
      return right_final
    end
  end

  def as_dict
    {
      bout_id: id,
      fotl_last_name: left_fencer.last_name,
      fotl_first_name: left_fencer.first_name,
      fotr_last_name: right_fencer.last_name,
      fotr_first_name: right_fencer.first_name,
      gfycats: gfycats.map{|g| g.gfycat_gfy_id},
      tournament_name: tournament.tournament_name,
      tournament_year: tournament.tournament_year
    }
  end

  def to_json
    as_dict.to_json
  end
  
  def self.json
    bouts = Bout.all.map{|bout| bout.as_dict}
    {
      count: bouts.length,
      bouts: bouts
    }.to_json
  end
end
