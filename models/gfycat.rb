class Gfycat < Sequel::Model
  one_to_many :form_responses
  def self.random_gfycat_id
    gfycat = Gfycat.all.sample
    raise RuntimeError.new("no gfycats found") if not gfycat
    gfycat
  end
  def self.tournaments
    tournaments = Gfycat.select(:tournament).distinct.map{|t| t[:tournament]}
    tournaments
  end
end
