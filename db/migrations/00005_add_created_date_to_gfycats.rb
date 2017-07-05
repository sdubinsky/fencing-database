Sequel.migration do
  up do
    add_column :gfycats, :created_date, Integer
  end

  down do
    drop_column :gfycats, :created_date, Integer
  end
end
