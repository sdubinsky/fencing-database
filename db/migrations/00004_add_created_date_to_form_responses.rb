Sequel.migration do
  up do
    add_column :form_responses, :created_date, Integer
  end

  down do
    drop_column :form_responses, :location
  end
end
