# -*- encoding : utf-8 -*-
$:.unshift File.expand_path('.')
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
set :rvm_type, :user

set :default_environment, {
  'LANG' => 'en_US.UTF-8'
}

#set :rake, "#{rake} --trace"

require 'rvm/capistrano'
require 'bundler/capistrano'
require 'delayed/recipes'
require 'airbrake/capistrano'

set :whenever_command, "bundle exec whenever"
# require "whenever/capistrano"

require 'capistrano/ext/multistage'
set :default_stage, "staging"
# set :stages, %w(production staging pingwinsoft) # auto readed

# main details
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

set :application, "rosa_build"
set(:deploy_to) { "/srv/#{application}" }
set :user, "rosa"
set :use_sudo, false
set :keep_releases, 3

set :scm, :git
set :repository,  "git@github.com:warpc/rosa-build.git"
set :deploy_via,  :remote_cache

require 'lib/recipes/nginx'
require 'lib/recipes/unicorn'
require 'lib/recipes/bluepill'

namespace :deploy do
  task :stub_xml_rpc do
    path = File.join(release_path, 'config', 'environment.rb')
    code = %Q{\nrequire 'stub_xml_rpc'\n}
    puts "Stub XML RPC"
    run %Q{echo "#{code}" >> #{path}}
  end

  task :symlink_all, :roles => :app do
    run "mkdir -p #{fetch :shared_path}/config"
    
    # Setup DB
    run "cp -n #{fetch :release_path}/config/database.yml.sample #{fetch :shared_path}/config/database.yml"
    run "ln -nfs #{fetch :shared_path}/config/database.yml #{fetch :release_path}/config/database.yml"
    
    # Setup application
    run "cp -n #{fetch :release_path}/config/deploy/application.#{fetch :stage}.yml #{fetch :shared_path}/config/application.yml"
    run "ln -nfs #{fetch :shared_path}/config/application.yml #{fetch :release_path}/config/application.yml"

    # It will survive downloads folder between deployments
    run "mkdir -p #{fetch :shared_path}/downloads"
    run "ln -nfs #{fetch :shared_path}/downloads/ #{fetch :release_path}/public/downloads"
  end

  task :symlink_pids, :roles => :app do
    run "cd #{fetch :shared_path}/tmp && ln -nfs ../pids pids"
  end
  
  # Speed up precompile (http://www.bencurtis.com/2011/12/skipping-asset-compilation-with-capistrano )
  # namespace :assets do
  #   task :precompile, :roles => :web, :except => { :no_release => true } do
  #     from = source.next_revision(current_revision)
  #     if capture("cd #{latest_release} && #{source.local.log(from)} app/assets/ lib/assets/ vendor/assets/  | wc -l").to_i > 0
  #       run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile"
  #     else
  #       logger.info "Skipping asset pre-compilation because there were no asset changes"
  #     end
  #   end
  # end  
end

after "deploy:finalize_update", "deploy:symlink_all"
after "deploy:update_code", "deploy:migrate"
after "deploy:setup", "deploy:symlink_pids"
# after "deploy:restart", "bluepill:start" # "bluepill:processes:restart_dj" # "bluepill:restart"

# DJ
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
# after "deploy:restart", "delayed_job:restart"

after "deploy:restart", "deploy:cleanup"

require 'cape'
namespace :rake_tasks do
  Cape do
    mirror_rake_tasks 'db:seeds'
  end
end
