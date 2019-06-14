Sequel.migration do
  up do
    alter_table :fencers do
      drop_column :fie_id
      add_column :fie_id, String
    end
  end

  down do
    alter_table :fencers do
      drop_column :fie_id
      add_column :fie_id, Integer
    end
  end
end
