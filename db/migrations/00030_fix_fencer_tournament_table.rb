Sequel.migration do
  change do
    alter_table :fencers_tournaments do
      rename_column :fencers_fie_id, :fencers_id
    end
  end
end
