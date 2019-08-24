Sequel.migration do
  change do
    alter_table :highlight_reels do
      add_foreign_key :user, :users
    end
  end
end
