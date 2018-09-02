require 'rake/testtask'
namespace :db do
  db_address = ENV["DATABASE_URL"] || "postgres://localhost/fencingstats"
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(db_address) do |db|
      Sequel::Migrator.run(db, "db/migrations", target: version)
    end
  end

  desc "Update gfycat list"
  task :update_gfycat_list do |t|
    require 'sequel'
    Sequel.connect db_address do |db|
      require './models/init'
      Gfycat.update_gfycat_list
    end
  end

  desc "Add new bouts"
  task :add_bouts do |t|
    require 'sequel'
    Sequel.connect db_address do |db|
      require './models/init'
      #Update gfys with any bouts that already exist
      db["update gfycats set bout_id = (select bouts.id as bout_id from bouts where bouts.left_fencer_id=gfycats.left_fencer_id and bouts.right_fencer_id=gfycats.right_fencer_id and bouts.tournament_id=gfycats.tournament_id);"].update
      #create new bouts from gfys that don't have bouts attached, but that should.  This is defined as gfys that have a left_fencer_id, a right_fencer_id, and a tournament, but no bout.
      db['insert into bouts (left_fencer_id, right_fencer_id, tournament_id) select distinct left_fencer_id, right_fencer_id, tournament_id from gfycats where left_fencer_id is not null and right_fencer_id is not null and bout_id is null;'].insert
      db["update gfycats set bout_id = (select bouts.id as bout_id from bouts where bouts.left_fencer_id=gfycats.left_fencer_id and bouts.right_fencer_id=gfycats.right_fencer_id and bouts.tournament_id=gfycats.tournament_id);"].update
    end
  end
end
