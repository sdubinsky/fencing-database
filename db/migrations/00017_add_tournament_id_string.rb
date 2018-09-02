Sequel.migration do
  change do
    alter_table :tournaments do
      add_column :tournament_id, String
    end
    
    alter_table :gfycats do
      drop_column :tournament
      add_foreign_key :tournament, :tournaments, key: :tournament_id, type: String
    end
  end
end
