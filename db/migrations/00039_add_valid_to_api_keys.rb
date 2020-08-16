Sequel.migration do
  change do
    alter_table :api_keys do
      add_column :valid, :boolean
    end
  end
end
