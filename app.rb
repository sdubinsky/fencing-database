require 'sinatra'
require 'sequel'
require 'psych'
config = Psych.load_file("./config.yml")
db_config = config['database']
if db_config['db_username'] or db_config['db_password']
  login = "#{db_config['db_username']}:#{db_config['db_password']}@"
else
  login = ''
end
Sequel.connect("postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}")

require './models/init'

configure :development do
  set :show_exceptions, true
end

set :root, File.dirname(__FILE__)

get '/' do
  @score_strip_locations = [:fotl_warning_strip, :fotl_half, :middle, :fotr_half, :fotr_warning_strip]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  @gfycat = Gfycat.random_gfycat_id
  erb :clip_form
end

get '/submit/?' do
  response = FormResponse.create(
    fotl_name: params['fotl-name'],
    fotr_name: params['fotr-name'],
    initiated: params['initiated-action'],
    strip_location: params['strip-location'],
    body_location: params['score-body-select'],
    gfycat_id: params['gfycat-id']
  )
  response.save
  redirect '/'
end

get '/submit_gfycat/?' do
  gfycat = Gfycat.new(
    gfycat_gfy_id: params['gfycat_id'],
    tournament: params['tournament'],
    weapon: params['weapon'],
    gender: params['gender']
  )
end
