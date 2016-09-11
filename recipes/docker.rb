#
# Cookbook Name:: kubernetes
# Recipe:: docker
#
# Copyright (C) 2016 Alex Litvinenko
#
# All rights reserved - Do Not Redistribute
#

# Configures Docker YUM Repository
include_recipe 'chef-yum-docker'

# Install Docker package from upstream repo, configures Systemd service
# and starts Docker daemon
docker_service 'default' do
  host 'unix:///var/run/docker.sock'
  version node['docker']['version']
  install_method 'package'
  storage_driver node['docker']['storage_driver']
  action [:create, :start]
end
