Sequel.migration do
  up do
    create_table :gfycats do
      primary_key :id
      String :gfycat_gfy_id, unique: true, null: false
      String :tournament
      String :weapon
      String :gender
    end
  end

  down do
    drop_table :gfycats
  end
end
