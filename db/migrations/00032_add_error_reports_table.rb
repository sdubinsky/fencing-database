Sequel.migration do
  change do
    create_table :error_reports do
      primary_key :id
      String :gfycat_gfy_id, null: false
      Boolean :resolved, default: false
      Integer :created_date, null: false
    end
  end
end
