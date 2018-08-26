Sequel.migration do
  up do
    add_column :fencers, :birthday, Date
  end

  down do
    drop_column :fencers, :birthday
  end
end
