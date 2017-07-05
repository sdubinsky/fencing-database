require 'psych'
namespace 'db' do
  desc 'migrate db'
  task :migrate do
    on roles(:web) do
      s = capture :cat, "#{release_path}/config.yml"
      db_config = Psych.load(s)['database']
      connstr = "postgres://#{db_config['db_username']}:#{db_config['db_password']}@#{db_config['db_address']}/#{db_config['db_name']}"
      puts connstr
      
      execute :sequel, '-m', "#{release_path}/db/migrations", "postgres://#{db_config['db_username']}:#{db_config['db_password']}@#{db_config['db_address']}/#{db_config['db_name']}"
    end
  end
  desc 'migrate db locally'
  task :migrate_local do
    run_locally do
      db_config = Psych.load_file('config.yml')['database'] 
      execute :sequel, '-m', "db/migrations", "postgres://#{db_config['db_username']}:#{db_config['db_password']}@#{db_config['db_address']}/#{db_config['db_name']}"
    end
  end
end
