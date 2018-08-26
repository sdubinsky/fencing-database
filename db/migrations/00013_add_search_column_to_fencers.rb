Sequel.migration do
  up do
    add_column :fencers, :search_name, String
  end

  down do
    drop_column :fencers, :search_name
  end
end
