Sequel.migration do
  up do
    add_column :gfycats, :fotl_name, String
    add_column :gfycats, :fotr_name, String
  end

  down do
    drop_column :gfycats, :fotl_name
    drop_column :gfycats, :fotr_name
  end
end
