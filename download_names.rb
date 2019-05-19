#Download the latest fencer's names, license #'s, countries, genders
require 'excon'
require 'pry'
require 'sequel'
require 'json'
Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower

if ENV['DATABASE_URL']
  connstr = ENV['DATABASE_URL']
else
  config = Psych.load_file("./config.yml")
  db_config = config['database']
  if db_config['db_username'] or db_config['db_password']
    login = "#{db_config['db_username']}:#{db_config['db_password']}@"
  else
    login = ''
  end
  connstr = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
end
DB = Sequel.connect connstr
require './models/init'

def download_fencer_names
  base_url = "http://fie.org"
  path = "/competitions/licenses?fencer_models_Licence%5BLastName%5D=&fencer_models_Licence%5BNationality%5D=&fencer_models_Licence%5BGenderId%5D=&fencer_models_Licence%5BLicTypeId%5D=T&fencer_models_Licence%5BCPYear%5D=&fencer_models_Licence_page="

  connection = Excon.new base_url, persistent: true
  pages = 1.upto(1600).map{|i| connection.get(path: path + i.to_s)}.select{|c| c.status == 200}
  fencers = pages.map{|p| parse_page p.body}.flatten
end

def upsert_fencers fencers
  DB.transaction do
    fencers.map do |fencer|
      gender = fencer[:gender] == 'M' ? 'male' : 'female'
      db_fencer = Fencer.first(first_name: fencer[:first_name],
                               last_name: fencer[:last_name],
                               nationality: fencer[:nationality])
      if db_fencer
        db_fencer.update(fie_id: fencer[:fie_id], gender: gender)
        db_fencer.save
      else
        Fencer.create(
          first_name: fencer[:first_name],
          last_name: fencer[:last_name],
          nationality: fencer[:nationality],
          gender: gender,
          fie_id: fencer[:fie_id]
        ).save
      end
    end
  end
end

def write_file fencers
  File.open("fencer_names.rb", 'w') do |f|
    fencers.each do |fencer|
      f.puts fencer.to_s
    end
  end
end

def parse_page page
  page.
    split("\n").
    select{|l| l.include? "<td>"}.
    map{|l2|
    l2.
      gsub(/(<\/td>|<\/tr>)/, "").
      gsub(/<td.*?>/, ":").
      split(":").
      map{|l| l.strip}
  }.map{|l| {last_name: l[1], first_name: l[2], nationality: l[3], gender: l[4], fie_id: l[5]}}
end

#fencers = download_fencer_names
fencers = File.readlines("fencers.txt")
fencers = fencers.map{|line| eval(line)}

upsert_fencers fencers
