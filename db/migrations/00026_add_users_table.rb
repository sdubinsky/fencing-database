Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :username
      String :email
      String :password_hash
      Integer :created_date, default: Time.now.to_i
    end
  end
end
