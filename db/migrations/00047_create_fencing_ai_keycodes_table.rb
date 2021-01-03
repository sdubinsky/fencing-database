Sequel.migration do
  change do
    create_table :fencing_ai_keycodes do
      primary_key :id
      String :keycode
      String :meaning
    end
  end
end
