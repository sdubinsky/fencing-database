Sequel.migration do
  change do
    alter_table :reel_clips do
      add_index :highlight_reel_id
    end
  end
end
