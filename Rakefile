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
      db[:gfycats].where(bout_id: nil).update(bout_id: Bout.select(:id).where(left_fencer_id: Sequel[:gfycats][:left_fencer_id], right_fencer_id: Sequel[:gfycats][:right_fencer_id], tournament_id: Sequel[:gfycats][:tournament_id]))
      #create new bouts from gfys that don't have bouts attached, but that should.  This is defined as gfys that have a left_fencer_id, a right_fencer_id, and a tournament, but no bout.
      Bout.insert([:left_fencer_id, :right_fencer_id,:tournament_id], Gfycat.distinct.select(:left_fencer_id, :right_fencer_id, :tournament_id).where(bout_id: nil).where(Sequel.~(left_fencer_id: nil)).where(Sequel.~(right_fencer_id: nil)))
      #reupdate with new bouts
      db[:gfycats].where(bout_id: nil).update(bout_id: Bout.select(:id).where(left_fencer_id: Sequel[:gfycats][:left_fencer_id], right_fencer_id: Sequel[:gfycats][:right_fencer_id], tournament_id: Sequel[:gfycats][:tournament_id]))
    end
  end
end
