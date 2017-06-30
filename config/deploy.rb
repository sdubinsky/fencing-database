# config valid only for current version of Capistrano
lock '3.6.1'

set :application, ''
set :repo_url, 'git://github.com/sdubinsky/fencing-database.git'

set :deploy_to, '/home/ec2-user/fencing-database'
