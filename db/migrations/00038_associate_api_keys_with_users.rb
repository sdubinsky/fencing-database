Sequel.migration do
  up do
    alter_table :api_keys do
      drop_column :owner
      add_foreign_key :user_id, :users
    end
  end

  down do
    alter_table :api_keys do
      drop_column :user_id
      add_column :owner, String
    end
  end
end
