Sequel.migration do
  change do
    create_table :fencers_tournaments do
      primary_key :id
      foreign_key :fencers_fie_id
      foreign_key :tournaments_id
    end
  end
end
