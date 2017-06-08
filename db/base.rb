require 'sequel'


DB.create_table :gfycats do
  primary_key :id
  String :gfycat_gfy_id
end

DB.create_table :stats_id do
  primary_key :id
  String :gfycat_id
  String :tournament
  String :weapon
  String :gender
end

DB.create_table :form_responses do
  primary_key :id
  foreign_key :stats_id
  String :fotl_name
  String :fotr_name
  String :initiated
  String :strip_location
  String :body_location
end
