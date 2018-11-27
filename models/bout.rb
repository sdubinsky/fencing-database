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

  def self.json id_number=nil
    if id_number
      bout = Bout[id_number]
      raise BoutNotFoundError if bout == nil
      {
        count: 1,
        bout: {
          bout_id: bout.id,
          fotl_last_name: bout.left_fencer.last_name,
          fotl_first_name: bout.left_fencer.first_name,
          fotr_last_name: bout.right_fencer.last_name,
          fotr_first_name: bout.right_fencer.first_name,
          gfycats: bout.gfycats.map{|g| g.gfycat_gfy_id},
          tournament_name: bout.tournament.tournament_name,
          tournament_year: bout.tournament.tournament_year
        }
      }.to_json
    else
      bouts = Bout.all.map do |bout|
        {
          bout_id: bout.id,
          fotl_last_name: bout.left_fencer.last_name,
          fotl_first_name: bout.left_fencer.first_name,
          fotr_last_name: bout.right_fencer.last_name,
          fotr_first_name: bout.right_fencer.first_name,
          gfycats: bout.gfycats.map{|g| g.gfycat_gfy_id},
          tournament_name: bout.tournament.tournament_name,
          tournament_year: bout.tournament.tournament_year
        }
      end
      puts bouts
      {
        count: bouts.length,
        bouts: bouts
      }.to_json
    end
  end
end

class BoutNotFoundError < Exception; end
