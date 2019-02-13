Sequel.migration do
  change do
    create_table :highlight_reels do
      primary_key :id
      Integer :created_date, default: Time.now.to_i
      String :author
      String :title
      String :last_name
      String :first_name
      String :tournament
    end
  end
end
