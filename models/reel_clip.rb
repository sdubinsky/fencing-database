class ReelClip < Sequel::Model
  many_to_one :highlight_reel
  one_to_one :gfycat
end
