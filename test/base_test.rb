require 'minitest/autorun'
require 'rack/test'
require 'sequel'
require 'sequel/core'
require 'sqlite3'
require 'pry'

class BaseTest < Minitest::Test
  DB = Sequel.sqlite
  Sequel.extension :migration
  Sequel::Migrator.run(DB, 'db/migrations', target: 30)
  require_relative '../models/init'
end
