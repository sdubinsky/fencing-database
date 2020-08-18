Sequel.migration do
  up do
    alter_table :api_keys do
      add_unique_constraint [:key], name: "api_keys_key_ukey"
    end
  end

  down do
    alter_table :api_keys do 
      drop_constraint :api_keys_key_ukey, type: :unique
    end
  end
end
