require 'pry'
require 'sequel'
require 'psych'
require 'json'
require 'excon'
require 'logger'
require 'levenshtein'


#Tesseract doesn't parse names perfectly.  This is how we make it better
config = Psych.load_file("./config.yml")
db_config = config['database']
if db_config['db_username'] or db_config['db_password']
  login = "#{db_config['db_username']}:#{db_config['db_password']}@"
else
  login = ''
end
connstr = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
DB = Sequel.connect(connstr)

require './models/init'
#Finds matches where:
#1. The only name available is the last name, and it has exactly one match
#2. There's a last name and some of the first name, and it has exactly one match
def check_names gfy_name
  names1 = Fencer.where(last_name: gfy_name)
  return names1.first if names1 and names1.count == 1
  names2 = Fencer.where(last_name: gfy_name.split(" ")[0...-1], first_name: /^#{gfy_name.split(" ")[-1]}/i)
  return names2.first if names2 and names2.count == 1
end
#first pass - just check if last name is a perfect match, and that only one fencer has that last name
Gfycat.where(valid: true).each do |gfy|
  right_name = check_names gfy.fotr_name
  if right_name
     gfy.update(
      right_fencer_id: right_name.id
    )
  end

  left_name = check_names gfy.fotl_name
  if left_name
     gfy.update(
       left_fencer_id: left_name.id
    )
  end
end
