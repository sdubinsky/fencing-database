require 'json'
require 'minitest/autorun'
require 'rack/test'
require_relative '../app.rb'

class TestApi < Minitest::Test
  include Rack::Test::Methods
  def setup
    
  end

  def app
    Sinatra::Application
  end

  def test_get_fencers
    get '/api/fencers/04082000000'
    assert_equal 200, last_response.status

    body = JSON.parse last_response.body
    assert_equal ['fie_id', 'last_name', 'first_name', 'nationality', 'gender', 'birthdate', 'weapon', 'opponents', 'bouts', 'gfycats'], body.keys
  end

  def test_get_gfycats
    get '/api/clips/bad_clip_id'
    assert_equal 404, last_response.status

    get '/api/clips/ImmaterialHeartyAmethystsunbird'
    assert_equal 200, last_response.status
    body = JSON.parse last_response.body
    assert_equal ['gfycat_gfy_id', 'tournament_id', 'weapon', 'gender', 'fotl_name', 'fotr_name', 'left_score', 'right_score', 'touch'], body.keys

    10.times do
      get '/api/clips/random/foil'
      assert_equal 'foil', JSON.parse(last_response.body)['weapon']
    end
  end

  def test_get_questions
    get '/api/clips/questions/'
    assert_equal 400, last_response.status

    get '/api/clips/questions/foil'
    assert_equal 2, JSON.parse(last_response.body).length

    get '/api/clips/questions/epee'
    assert_equal 3, JSON.parse(last_response.body).length
  end
end
