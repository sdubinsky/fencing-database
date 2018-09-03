Sequel.migration do
  change do
    alter_table :fencers do
      add_column :weapon, String
    end
  end
end
