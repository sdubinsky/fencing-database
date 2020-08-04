class User < Sequel::Model
  one_to_many :highlight_reels
  one_to_many :form_responses
end
