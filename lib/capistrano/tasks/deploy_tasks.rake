namespace :deploy do
  desc 'restart server'
  task :restart_server do
    on roles :web do
      within release_path do
        execute :god, 'restart server'
      end
    end
  end

  desc 'start server'
  task :start_server do
    on roles :web do
      within release_path do
        execute :god, 'start server'
      end
    end
  end

  desc 'stop server'
  task :stop_server do
    on roles :web do
      within release_path do
        execute :god, 'stop server'
      end
    end
  end

  task :hard_restart_server do
    on roles :web do
      within release_path do
        execute :god, 'terminate'
        execute :god, '-c server.god'
      end
    end
  end
  desc 'start god process and server'
  task :cold_start do
    on roles :web do
      within release_path do
        invoke "bundler:install"
        execute :god, '-c server.god'
      end
    end
  end
  after 'cleanup', 'hard_restart_server' 
end

