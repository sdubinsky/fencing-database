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

  desc "normalize gfycat names"
  task :normalize_names do |t|
    require 'sequel'
    Sequel.connect db_address do |db|
      require './models/init'
      Gfycat.where(left_fencer_id: nil).or(right_fencer_id: nil).each{|gfy| gfy.normalize_names}
      Fencer.where(weapon: nil).where(id: Gfycat.where(weapon: 'epee').select(:left_fencer_id)).or(id: Gfycat.where(weapon: 'epee').select(:right_fencer_id)).update(weapon: 'epee')
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
      #Also add bouts to gfys that have duplicate names
      db[:gfycats].with(:g2, db[:gfycats].distinct.select(:left_fencer_id, :right_fencer_id, :fotl_name, :fotr_name, :bout_id, :tournament_id).exclude(left_fencer_id: nil).exclude(right_fencer_id: nil).exclude(bout_id: nil)).from(:gfycats, :g2).where(Sequel[:gfycats][:fotl_name] => Sequel[:g2][:fotl_name], Sequel[:g2][:fotl_name] => Sequel[:gfycats][:fotl_name], Sequel[:g2][:fotr_name] => Sequel[:gfycats][:fotr_name]).update(bout_id: Sequel[:g2][:bout_id], left_fencer_id: Sequel[:g2][:left_fencer_id], right_fencer_id: Sequel[:g2][:right_fencer_id])
    end
  end
end
