Sequel.migration do
  change do
    create_table :canonical_names do
      primary_key :id
      String :gfy_name
      foreign_key :fencer_id, :fencers
    end
  end
end
