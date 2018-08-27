Sequel.migration do
  change do
    create_table :bouts do
      primary_key :id
      foreign_key :tournament_id
      String :round
      foreign_key :left_fencer_id, :fencers
      foreign_key :right_fencer_id, :fencers
    end

    alter_table :gfycats do
      add_foreign_key :bout_id, :bouts
    end
  end
end
