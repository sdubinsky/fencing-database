Sequel.migration do
  change do
    alter_table :gfycats do
      add_column :left_score, Integer
      add_column :right_score, Integer
    end
  end
end
