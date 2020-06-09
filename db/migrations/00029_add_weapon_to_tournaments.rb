Sequel.migration do
  up do
    alter_table :tournaments do
      add_column :weapon, String
    end
    from(:tournaments).update(weapon: 'epee')
  end

  down do
    drop_column :weapon
  end
end


