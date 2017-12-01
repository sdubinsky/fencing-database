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
  def self.fencer_names 
    fencer_names = Gfycat.select(:fotl_name).all
    fencer_names = fencer_names + Gfycat.select(:fotr_name).all
    fencer_names.map!{|a| a[:fotl_name].to_s}
    fencer_names.uniq!
    fencer_names.sort
  end
end
