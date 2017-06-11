class Gfycat < Sequel::Model
  one_to_many :form_responses
  def self.random_gfycat_id
    maxval = Gfycat.count
    random_id = rand(maxval) + 1
    gfycat = self.where(id: random_id).first
    raise RuntimeError.new("no gfycats found") if not gfycat
    gfycat
  end
end
