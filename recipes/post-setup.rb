#
# Cookbook Name:: kubernetes
# Recipe:: post-setup
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

execute 'skydns_register_node' do
  only_if { node['skydns_enabled'] }
  command "curl -XPUT #{node['kubernetes']['etcd']['members'][0]}/v2/keys/skydns/#{node['skydns']['tld']}/#{node['skydns']['domain_name']}/#{node['hostname']} -d value='{ \"host\": \"#{node['ipaddress']}\" }'"
  action :run
end
