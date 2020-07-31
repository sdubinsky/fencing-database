Sequel.migration do
  change do
    alter_table :highlight_reels do
      rename_column :user, :user_id
    end
  end
end
