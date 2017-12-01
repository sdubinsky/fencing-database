Sequel.migration do
  up do
    drop_column :form_responses, :fotl_name
    drop_column :form_responses, :fotr_name
  end

  down do
    add_column :form_responses, :fotl_name, String
    add_column :form_responses, :fotr_name, String
  end
end
