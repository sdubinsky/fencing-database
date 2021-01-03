#takes a url and a tournament id, and adds the data
#to the tournaments_fencers table

#TODO: add tournament arg, save license numbers instead of printing them,
#      upload everything to the db, make sure we can upload it to heroku 

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


def download_entries url
  connection = Excon.new url, persistent: true
  page = connection.get
  page = page.body
  lines = page.gsub("\n", "")
  lines = lines.split("<tr>")
  lines = lines.select{|l| l.include? "<td"}
  lines = lines.map{|row| row.split("</td>").map{|entry| entry.gsub(/<.?td.*?>/, "").strip}}
end

url_ids = {'budapest2020': ['https://fie.org/competition/2020/112/entry/pdf?lang=en',
                            'https://fie.org/competition/2020/449/entry/pdf?lang=en'],
           'barcelona2020': ['https://fie.org/competition/2020/85/entry/pdf?lang=en'],
           'qatar2020': ['https://fie.org/competition/2020/387/entry/pdf?lang=en',
                         'https://fie.org/competition/2020/79/entry/pdf?lang=en'],
           'tallinn2019': ['https://fie.org/competition/2020/80/entry/pdf?lang=en'],
           'berne2019': ['https://fie.org/competition/2020/385/entry/pdf?lang=en'],
           'budapestwch2019': ['https://fie.org/competition/2019/242/entry/pdf?lang=en',
                               'https://fie.org/competition/2019/241/entry/pdf?lang=en'],
           'dubai2019': ['https://fie.org/competition/2019/451/entry/pdf?lang=en'],
           'cali2019': ['https://fie.org/competition/2019/95/entry/pdf?lang=en',
                        'https://fie.org/competition/2019/113/entry/pdf?lang=en'] ,
           'barcelona2019': ['https://fie.org/competition/2019/85/entry/pdf?lang=en'],
           'bern2018': ['https://fie.org/competition/2019/385/entry/pdf?lang=en'],
           'heidenheim2018': ['https://fie.org/competition/2018/98/entry/pdf?lang=en'],
           'dubai2018': ['https://fie.org/competition/2018/451/entry/pdf?lang=en'],
           'wuxi2018': ['https://fie.org/competition/2018/242/entry/pdf?lang=en',
                        'https://fie.org/competition/2018/241/entry/pdf?lang=en'],
           'barcelona2018': ['https://fie.org/competition/2018/92/entry/pdf?lang=en'],
           'cali2018': ['https://fie.org/competition/2018/95/entry/pdf?lang=en',
                        'https://fie.org/competition/2018/113/entry/pdf?lang=en'],
           'berne2017': ['https://fie.org/competition/2018/385/entry/pdf?lang=en'],
           'doha2017': ['https://fie.org/competition/2018/79/entry/pdf?lang=en',
                        'https://fie.org/competition/2018/387/entry/pdf?lang=en'],
           'heidenheim2017': ['https://fie.org/competition/2017/98/entry/pdf?lang=en'],
           'barcelona2016': ['https://fie.org/competition/2017/85/entry/pdf?lang=en'],
           'heidenheim2019': ['https://fie.org/competition/2019/108/entry/pdf?lang=en'],
           'doha2019': ['https://fie.org/competition/2019/387/entry/pdf?lang=en',
                        'https://fie.org/competition/2019/79/entry/pdf?lang=en'],
           'budapest2019': ['https://fie.org/competition/2019/112/entry/pdf?lang=en',
                            'https://fie.org/competition/2019/449/entry/pdf?lang=en'],
           'montrealsabre2020': ['https://fie.org/competition/2020/152/entry/pdf?lang=en',
                                 'https://fie.org/competition/2020/158/entry/pdf?lang=en'],
           'cairosabre2019': ['https://fie.org/competition/2019/152/entry/pdf?lang=en',
                              'https://fie.org/competition/2019/158/entry/pdf?lang=en'],
           'seoulsabre2019': ['https://fie.org/competition/2019/165/entry/pdf?lang=en',
                              'https://fie.org/competition/2019/468/entry/pdf?lang=en'],
           'cancunsabre2017': ['https://fie.org/competition/2018/152/entry/pdf?lang=en',
                               'https://fie.org/competition/2018/158/entry/pdf?lang=en'],
           'turinfoil2020': ['https://fie.org/competition/2020/134/entry/pdf?lang=en',
                             'https://fie.org/competition/2020/458/entry/pdf?lang=en'],
           'moscowsabre2012': ['https://fie.org/competition/2012/156/entry/pdf?lang=en',
                               'https://fie.org/competition/2012/468/entry/pdf?lang=en'],
           'katowicefoil2019': ['https://fie.org/competition/2019/118/entry/pdf?lang=en'],
           'kazanfoil2020': ['https://fie.org/competition/2020/129/entry/pdf?lang=en'],
           'stpetersburgfoil2019': ['https://fie.org/competition/2019/147/entry/pdf?lang=en'],
           'kazanwch2014': ['https://fie.org/competition/2014/242/entry/pdf?lang=en',
                            'https://fie.org/competition/2014/241/entry/pdf?lang=en'],
           'tunissabre2017': ['https://fie.org/competition/2017/471/entry/pdf?lang=en'],
            'anaheimfoil2019': ['https://fie.org/competition/2019/140/entry/pdf?lang=en',
                               'https://fie.org/competition/2019/121/entry/pdf?lang=en'],
}

Sequel.connect connstr do |db|
  require './models/init'
  url_ids.reject! do |tournament_key, urls|
    tournament = Tournament.select(:id, :weapon).first(tournament_id: tournament_key.to_s)
    raise "Error: No tournament found for id #{tournament_key}" unless tournament
    old_entries = db[:fencers_tournaments].where(tournaments_id: tournament.id).count
    old_entries > 0
  end
end
url_ids.each do |tournament_key, urls|
  puts "adding entries from #{tournament_key}"
  urls.each do |url|
    entries = download_entries url
    licenses = entries.map{|entry| entry[4]}
    Sequel.connect connstr do |db|
      require './models/init'
      tournament = Tournament.select(:id, :weapon).first(tournament_id: tournament_key.to_s)
      db.transaction do
        entries.each do |entry|
          if Fencer.where(fie_id: entry[4]).count == 0
            Fencer.create(
              last_name: entry[0].split[0],
              first_name: entry[0].split[1],
              nationality: entry[1][0..2],
              birthday: entry[6],
              weapon: tournament.weapon,
              fie_id: entry[4]
            )
          end
          select = Fencer.select(:id, tournament.id).where(fie_id: licenses)
          db[:fencers_tournaments].insert([:fencers_id, :tournaments_id], select)
        end
      end
    end
  end
end
