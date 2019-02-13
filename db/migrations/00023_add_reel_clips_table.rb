Sequel.migration do
  change do
    create_table :reel_clips do
      primary_key :id
      String :gfycat_gfy_id
      foreign_key :highlight_reel_id, :highlight_reels
      Boolean :selected
    end
  end
end
