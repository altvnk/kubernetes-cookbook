#
# Cookbook Name:: kubernetes
# Recipe:: client_wrapper
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'chef-client::systemd_service'

node[:role].push('etcd') if tagged?('etcd') && !node[:role].include?('etcd')
node[:role].push('master') if tagged?('master') && !node[:role].include?('master')
node[:role].push('slave') if tagged?('slave') && !node[:role].include?('slave')
