require 'sinatra'
require 'sequel'
require 'psych'
require 'json'

config = Psych.load_file("./config.yml")
db_config = config['database']
if db_config['db_username'] or db_config['db_password']
  login = "#{db_config['db_username']}:#{db_config['db_password']}@"
else
  login = ''
end
connstr = "postgres://#{login}#{db_config['db_address']}/#{db_config['db_name']}"
DB = Sequel.connect(connstr)

require './models/init'

configure :development do
  set :show_exceptions, true
end

set :root, File.dirname(__FILE__)

get '/' do
  @score_strip_locations = [:fotl_warning_strip, :fotl_half, :middle, :fotr_half, :fotr_warning_strip]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  begin
    @gfycat = Gfycat.random_gfycat_id
  rescue RuntimeError
    status 500
    return
  end
  erb :clip_form
end

get '/submit/?' do
  response = FormResponse.create(
    fotl_name: params['fotl-name'],
    fotr_name: params['fotr-name'],
    initiated: params['initiated-action'],
    strip_location: params['strip-location'],
    body_location: params['score-body-select'],
    gfycat_id: params['gfycat-id'],
    created_date: Time.now.to_i
  )
  response.save
  redirect '/'
end

post '/submit_gfycats/?' do
  request.body.rewind
  payload = JSON.parse request.body.read
  payload['gfycats'].each do |gfy|
    begin
      Gfycat.new(
        gfycat_gfy_id: gfy['gfycat_id'],
        tournament: gfy['tournament'],
        weapon: gfy['weapon'],
        gender: gfy['gender'],
        created_date: Time.now.to_i
      ).save
    rescue Sequel::UniqueConstraintViolation
      puts "duplicate gfy id: #{gfy['gfycat_id']}"
    end
  end
  
  status 200

end
