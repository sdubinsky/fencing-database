Sequel.migration do
  up do
    alter_table :bouts do
      set_column_type :tournament_id, String
    end
  end

  down do
    alter_table :bouts do
      set_column_type :tournament_id, Integer
    end
  end
end
