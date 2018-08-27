Sequel.migration do
  change do
    create_table :tournaments do
      primary_key :id
      String :tournament_name
      String :tournament_year
    end
  end
end
