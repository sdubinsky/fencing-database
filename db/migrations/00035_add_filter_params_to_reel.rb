Sequel.migration do
  change do
    alter_table :highlight_reels do
      add_column :filter_params, String
    end
  end
end
