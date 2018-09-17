class Bout < Sequel::Model
  one_to_many :gfycats
  many_to_one :tournament, key: :tournament_id, primary_key: :tournament_id

  def final_touch
    left_final = gfycats_dataset.order_by(:left_score).reverse.limit(1)
    right_final = gfycats_dataset.order_by(:left_score).reverse.limit(1)
    if left_final.first.left_score < right_final.first.right_score
      return left_final
    else
      return right_final
    end
  end
end
