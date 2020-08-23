Sequel.migration do
  change do
    alter_table :gfycats do
      add_index :gfycat_gfy_id
    end
  end
end
