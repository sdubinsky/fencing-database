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

'''
1. Take list of all names from DB.
2. Concatenate last name and first initial.
3. Remove all spaces.
4. Lowercase all.
5. Find name with lowest levenshtein distance.
'''

def check_name gfy_name
  names1 = Fencer.where(last_name: gfy_name)
  return names1.first if names1 and names1.count == 1
  names2 = Fencer.where(last_name: gfy_name.split(" ")[0..-1].join(" "))
  return names2.first if names2 and names2.count == 1
  names3 = Fencer.where(last_name: gfy_name, first_name: /$#{gfy_name.split(" ")[-1][0]}/)
  return names3.first if names3 and names3.count == 1
end
#first pass - just check if last name is a perfect match, and that only one fencer has that last name
Gfycat.each do |gfy|
  right_name = check_name gfy.fotr_name
  if right_name
    puts "#{gfy.fotr_name} matches with #{right_name.name}"
    # gfy.update(
    #   right_fencer_id: right_name.id
    # )
  end

  left_name = check_name gfy.fotl_name
  if left_name
    puts "#{gfy.fotl_name} matches with #{left_name.name}"
    # gfy.update(
    #   left_fencer_id: left_name.first.id
    # )
  end
end
