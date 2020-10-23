Sequel.migration do
  change do
    alter_table :highlight_reels do
      add_column :ready_for_upload, :boolean, default: false
    end
  end
end
