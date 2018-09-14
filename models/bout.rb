class Bout < Sequel::Model
  one_to_many :gfycats
  many_to_one :tournament, key: :tournament_id, primary_key: :tournament_id
end
