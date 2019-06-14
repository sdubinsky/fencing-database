Sequel.migration do
  change do
    alter_table :reel_clips do
      add_column :round, Integer
    end

    alter_table :highlight_reels do
      add_column :round, Integer, default: 1
    end
  end
end
