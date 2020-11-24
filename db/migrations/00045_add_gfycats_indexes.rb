Sequel.migration do
  change do
    alter_table :gfycats do
      add_index :tournament_id
      add_index :left_fencer_id
      add_index :right_fencer_id
      add_index :left_score
      add_index :right_score
      add_index :touch
      add_index :gender
    end
  end
end
