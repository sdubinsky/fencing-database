class ReelClip < Sequel::Model
  many_to_one :highlight_reel

  def url
    "https://giant.gfycat.com/#{gfycat_gfy_id}.webm"
  end
end
