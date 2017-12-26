Sequel.migration do
  up do
    add_column :gfycats, :touch, String 
  end

  down do
    drop_column :gfycats, :touch
  end
end
