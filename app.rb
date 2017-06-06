require 'sinatra'

configure :development do
  set :show_exceptions, true
end


get '/' do
  @score_strip_locations = [:fotl_warning_strip, :fotl_half, :middle, :fotr_half, :fotr_warning_strip]
  @score_body_locations = [:hand, :front_arm, :torso, :head, :front_leg, :foot, :back_arm, :back_leg]
  erb :clip_form
end
