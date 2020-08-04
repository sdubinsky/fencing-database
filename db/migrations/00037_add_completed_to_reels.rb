Sequel.migration do
  change do
    alter_table :highlight_reels do
      add_column :completed, :boolean, default: false
    end
  end
end
