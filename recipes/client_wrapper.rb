#
# Cookbook Name:: kubernetes
# Recipe:: client_wrapper
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'chef-client::systemd_service'

node.run_list.add('role[etcd]') if node[:tags].include? 'etcd'
node.run_list.add('role[master]') if node[:tags].include? 'master'
node.run_list.add('role[slave]') if node[:tags].include? 'slave'
