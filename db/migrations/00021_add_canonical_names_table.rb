Sequel.migration do
  change do
    create_table :canonical_names do
      primary_key :id
      String :gfy_name
      String :canonical_name
    end
  end
end
