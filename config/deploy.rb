# Config valid for current version and patch releases of Capistrano
lock '~> 3.14.1'

set :application, 'guava_inn'
set :repo_url, 'git@github.com:heitorado/guava-inn-20.git'
set :branch, 'trunk'

# Symlink config/master.key to the shared folder
append :linked_files, 'config/master.key'

# Upload config/master.key if it does not exist on server shared/config
namespace :deploy do
  namespace :check do
    before :linked_files, :set_master_key do
      on roles(:web), in: :sequence, wait: 10 do
        unless test("[ -f #{shared_path}/config/master.key ]")
          upload! 'config/master.key', "#{shared_path}/config/master.key"
        end
      end
    end
  end
end

# Symlink config/nginx.conf to the shared folder
append :linked_files, 'config/nginx.conf'

# Always upload config/nginx.conf
namespace :deploy do
  namespace :check do
    before :linked_files, :set_nginx_conf do
      on roles(:web), in: :sequence, wait: 10 do
        upload! 'config/nginx.conf', "#{shared_path}/config/nginx.conf"
      end
    end
  end
end

# Rbenv settings
set :rbenv_type, :user
set :rbenv_ruby, '2.7.1'
set :rbenv_roles, :all
append :rbenv_map_bins, 'puma', 'pumactl'

# Puma settings
set :puma_threads,    [4, 16]
set :puma_workers,    2
set :puma_init_active_record, true

namespace :puma do
  desc 'Create Directories for Puma Pids, Sockets and Logs'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
      execute "mkdir #{shared_path}/log -p"
    end
  end

  before :start, :make_dirs
end

# Tasks for initial deploy and puma restart
namespace :deploy do
  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

