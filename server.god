require 'psych'
god_config = Psych.load_file("./config.yml")['god']

God.watch do |w|
  w.name = 'server'
  w.env = {
    'APP_ENV' => god_config['app_env']
  }
  w.dir = god_config['dir']
  w.start = 'bundle exec ruby app.rb'
  w.behavior :clean_pid_file
  w.log = god_config['dir'] + '/log/server.log'
  w.keepalive
end
