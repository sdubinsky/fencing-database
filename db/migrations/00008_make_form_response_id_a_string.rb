Sequel.migration do
  up do 
    set_column_type :form_responses, :stats_id, String
  end

  down do
    set_column_type :form_responses, :stats_id, Integer
  end
end
