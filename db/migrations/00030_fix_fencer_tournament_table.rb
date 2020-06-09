Sequel.migration do
  change do
    rename_column :fencer_fie_id, :fencer_id
  end
end
