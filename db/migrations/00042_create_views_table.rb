Sequel.migration do
  change do
    create_table :views do
      primary_key :id
      String :endpoint
      String :http_method
      String :form_data
      String :country_code
      String :viewer_ip
      Integer :created_at
    end
  end
end
