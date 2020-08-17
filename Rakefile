require 'json'
require 'excon'
require 'psych'
require 'rake/testtask'
namespace :db do
  
  if  ENV["DATABASE_URL"]
    db_address = ENV["DATABASE_URL"]
  else
    config = Psych.load_file("./config.yml")
    db_config = config['database']
    if db_config['db_username'] or db_config['db_password']
      login = "#{db_config['db_username']}:#{db_config['db_password']}@"
    else
      login = ''
    end
    db_address = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
  end
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(db_address) do |db|
      Sequel::Migrator.run(db, "db/migrations", target: version)
    end
  end

  desc "normalize gfycat names"
  task :normalize_names do |t|
    require 'sequel'
    Sequel.connect db_address do |db|
      require './models/init'
      gfys = Gfycat.where(left_fencer_id: nil).or(right_fencer_id: nil).all
      db.transaction do
        gfys.each{|gfy| gfy.normalize_names}
      end
      Fencer.where(weapon: nil).where(id: Gfycat.where(weapon: 'epee').select(:left_fencer_id)).or(id: Gfycat.where(weapon: 'epee').select(:right_fencer_id)).update(weapon: 'epee')
      Fencer.where(weapon: nil).where(id: Gfycat.where(weapon: 'sabre').select(:left_fencer_id)).or(id: Gfycat.where(weapon: 'sabre').select(:right_fencer_id)).update(weapon: 'sabre')
      Fencer.where(weapon: nil).where(id: Gfycat.where(weapon: 'foil').select(:left_fencer_id)).or(id: Gfycat.where(weapon: 'foil').select(:right_fencer_id)).update(weapon: 'foil')

      Fencer.where(gender: nil).where(id: Gfycat.where(gender: 'male').select(:left_fencer_id)).or(id: Gfycat.where(gender: 'male').select(:right_fencer_id)).update(gender: 'male')
      Fencer.where(gender: nil).where(id: Gfycat.where(gender: 'female').select(:left_fencer_id)).or(id: Gfycat.where(gender: 'female').select(:right_fencer_id)).update(gender: 'female')
    end
  end

  desc "Add new bouts"
  task :add_bouts do |t|
    require 'sequel'
    Sequel.connect db_address do |db|
      require './models/init'
      puts "starting with #{Bout.count} bouts"
      #Update gfys with any bouts that already exist
      db[:gfycats]
        .where(bout_id: nil)
        .update(bout_id: Bout.select(:id)
                  .where(left_fencer_id: Sequel[:gfycats][:left_fencer_id],
                         right_fencer_id: Sequel[:gfycats][:right_fencer_id],
                         tournament_id: Sequel[:gfycats][:tournament_id]))
      #create new bouts from gfys that don't have bouts attached, but that should.  This is defined as gfys that have a left_fencer_id, a right_fencer_id, and a tournament, but no bout.
      Bout.insert([:left_fencer_id, :right_fencer_id,:tournament_id],
                  Gfycat.distinct.select(:left_fencer_id, :right_fencer_id,
                                         :tournament_id)
                    .where(bout_id: nil)
                    .where(Sequel.~(left_fencer_id: nil))
                    .where(Sequel.~(right_fencer_id: nil)))
      
      #reupdate with new bouts
      db[:gfycats]
        .where(bout_id: nil)
        .update(bout_id: Bout.select(:id)
                  .where(left_fencer_id: Sequel[:gfycats][:left_fencer_id],
                         right_fencer_id: Sequel[:gfycats][:right_fencer_id],
                         tournament_id: Sequel[:gfycats][:tournament_id]))
      
      #Also add bouts to gfys that have duplicate names
      db[:gfycats]
        .with(:g2, db[:gfycats]
                     .distinct
                     .select(:left_fencer_id, :right_fencer_id,
                             :fotl_name, :fotr_name,
                             :bout_id, :tournament_id)
                     .exclude(left_fencer_id: nil)
                     .exclude(right_fencer_id: nil)
                     .exclude(bout_id: nil))
        .from(:gfycats, :g2)
        .where(Sequel[:gfycats][:tournament_id] => Sequel[:g2][:tournament_id],
               Sequel[:g2][:fotl_name] => Sequel[:gfycats][:fotl_name],
               Sequel[:g2][:fotr_name] => Sequel[:gfycats][:fotr_name])
        .update(bout_id: Sequel[:g2][:bout_id],
                left_fencer_id: Sequel[:g2][:left_fencer_id],
                right_fencer_id: Sequel[:g2][:right_fencer_id])

      puts "ending with #{Bout.count} bouts"
    end
  end

  desc "Update gfycat list"
  task :update_gfycat_list do |t|
    require 'sequel'
    def get_access_token
      secrets = Psych.load_file('gfycat_secrets.yml')
      body = {
        grant_type:  "password",
        username:  secrets['username'],
        password: secrets['password'],
        client_id: secrets['client_id'],
        client_secret: secrets['client_secret']
      }
      response = Excon.post(
        "https://api.gfycat.com/v1/oauth/token",
        headers: {"Content-Type" => "application/json"},
        body: body.to_json
      )
      response = JSON.parse response.body
      response['access_token']
    end
    access_token = get_access_token
    tournaments = []
    old_gfycats = []
    Sequel.connect(db_address) do |db|
      require './models/init'
      old_gfycats = Gfycat.map(:gfycat_gfy_id) + ["EnchantedTatteredBasilisk", 'UltimateThoughtfulArizonaalligatorlizard', 'FormalWideIberianbarbel', 'CluelessFatCockatoo']
      tournaments = Tournament.select(:tournament_id).to_a
      puts "old gfycat count: #{old_gfycats.length}"
    end
    connection = Excon.new "https://api.gfycat.com", persistent: true
    path = '/v1/me/gfycats'
    next_round = JSON.parse connection.get(path: path + '?count=500', headers: {"Authorization" => "Bearer #{access_token}"}).body
    all_gfycats = next_round['gfycats']
    cursor = next_round['cursor']
    until (not cursor) or cursor.empty? do
      next_round = JSON.parse connection.get(path: path + "?count=500&cursor=#{cursor}", headers: {"Authorization" => "Bearer #{access_token}"}).body
      cursor = next_round['cursor']
      all_gfycats = all_gfycats + next_round['gfycats'] if next_round['gfycats']
    end
    old_gfycats.sort!
    new_gfycats = all_gfycats.reject{|a| old_gfycats.bsearch{|b| a['gfyName'] <=> b }}
    puts "new gfycats count: #{new_gfycats.length}"
    Sequel.connect(db_address) do |db|
      require './models/init'
      db.transaction do
        new_gfycats.each do |gfy|
          if gfy['tags'] and gfy['tags'].join.include? 'tournament'
            tags = Hash[gfy['tags'].map{|x| x.split ": "}]
          else
            next
          end
          left_score = tags['leftscore'] || -1
          right_score = tags['rightscore'] || -1
          if tournaments.include? tags['tournament'] and not tags['tournament'].nil?
            $stderr.puts "#{tags['tournament']} doesn't exist"
            exit(1)
          end
          tournament_id = tags['tournament']
          begin
            db[:gfycats].insert(
              gfycat_gfy_id: gfy['gfyName'],
              tournament_id: tournament_id,
              weapon: tags['weapon'],
              gender: tags['gender'],
              created_date: Time.now.to_i,
              fotl_name: tags['leftname'],
              fotr_name: tags['rightname'],
              left_score: left_score,
              right_score: right_score,
              touch: tags['touch']
            )
          rescue => e
            $stderr.puts e.to_s
            exit 1
          end
        end
      end
    end
  end
  desc "update the gfycats, normalize the names, and add bouts"
  task :update_gfycats => [:update_gfycat_list, :normalize_names, :add_bouts]
end
