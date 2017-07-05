Sequel.migration do
  up do
    create_table :api_keys do
      primary_key :id
      String :key, null: false
      String :owner, null: false
      Integer :created_date, null: false
    end
  end

  down do
    drop_table :api_keys
  end
end
