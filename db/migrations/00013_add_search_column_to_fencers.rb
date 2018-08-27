Sequel.migration do
  up do
    add_column :fencers, :search_name, String
    add_column :fencers, :fie_id, Integer
  end

  down do
    drop_column :fencers, :search_name
    drop_column :fencers, :fie_id
  end
end
