Sequel.migration do
  change do
    alter_table :fencers do
      add_index :last_name
      add_index :first_name
      add_index :gender
      add_index :weapon
    end
  end
end
