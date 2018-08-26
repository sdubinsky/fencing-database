Sequel.migration do
  up do
    create_table :fencers do
      primary_key :id
      String :last_name
      String :first_name
      String :handedness
      String :nationality
      String :gender
    end      
  end

  down do
    drop_table :fencers
  end
end
