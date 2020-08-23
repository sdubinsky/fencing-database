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

  def test_last_name_first_initial
    DB.transaction(rollback: :always) do
      test_gfycat = Gfycat.new(
        gfycat_gfy_id: 'testgfy',
        fotl_name: 'apithy b',
        fotr_name: 'ibragimov k',
        tournament_id: 'moscowsabre2012',
        weapon: 'sabre'
      )
      assert_nil test_gfycat.left_fencer_id
      test_gfycat.normalize_names
      assert_equal 1785, test_gfycat.left_fencer_id
      assert_equal 1868, test_gfycat.right_fencer_id
    end
  end
end
