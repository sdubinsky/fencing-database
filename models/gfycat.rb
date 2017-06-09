class Gfycat < Sequel::Model
  def self.random_gfycat_id
    maxval = Gfycat.count
    random_id = rand(maxval) + 1
    self.where(id: random_id).first.gfycat_gfy_id
  end
end
