Sequel.migration do
  change do
    alter_table :gfycats do
      add_column :valid, TrueClass, default: true
    end
  end
end
