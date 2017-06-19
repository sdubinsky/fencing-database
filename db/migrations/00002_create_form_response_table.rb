Sequel.migration do
  up do
    create_table :form_responses do
      primary_key :id
      foreign_key :stats_id
      String :fotl_name
      String :fotr_name
      String :initiated
      String :strip_location
      String :body_location
    end
  end

  down do
    drop_table :form_responses
  end
end
