Sequel.migration do
  change do
    create_table :fencing_ai_results do
      primary_key :id
      String :keycode
      Integer :timestamp
      foreign_key :user_id
      foreign_key :reel_clip_id
    end
  end
end
