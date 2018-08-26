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
end
