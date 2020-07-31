class HighlightReel < Sequel::Model
  one_to_many :reel_clips
  many_to_one :user
  def export_reel
    ReelClip.where(selected: true, highlight_reel_id: id).map{|clip| "wget #{clip.url}"}.join "<br />"
  end
end
