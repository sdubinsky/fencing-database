require 'json'
require 'minitest/autorun'
require 'rack/test'
require_relative '../app.rb'

class TestNormalizeNames < Minitest::Test
  include Rack::Test::Methods
  def setup
    
  end

  def app
    Sinatra::Application
  end

  def test_find_name_possibilities
    names = Fencer.find_name_possibilities 'ibragimov k', 29
    assert_equal 1, names.all.length
    
  end
end
