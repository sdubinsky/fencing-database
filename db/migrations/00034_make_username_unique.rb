Sequel.migration do
  up do
    alter_table :users do
      add_unique_constraint [:username], name: "users_username_ukey"
    end
  end

  down do
    alter_table :users do
      drop_constraint(:users_username_ukey, type: :unique)
    end
  end
end
