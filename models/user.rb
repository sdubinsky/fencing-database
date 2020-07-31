class User < Sequel::Model
  one_to_many :highlight_reels
end
