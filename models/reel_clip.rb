class ReelClip < Sequel::Model
  many_to_one :highlight_reel
  one_to_one :gfycat, key: :gfycat_gfy_id, primary_key: :gfycat_gfy_id

  def url
    "https://giant.gfycat.com/#{gfycat_gfy_id}.webm"
  end
end
