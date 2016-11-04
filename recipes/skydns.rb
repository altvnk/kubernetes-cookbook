#
# Cookbook Name:: kubernetes
# Recipe:: skydns
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

# create skydns conf directories
directory '/etc/skydns' do
  recursive true
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# render conf templates
template '/etc/systemd/system/skydns.service' do
  mode '0640'
  source 'skydns.erb'
end

template '/etc/skydns/skydns-env' do
  mode '0666'
  source 'skydns-env.erb'
  variables(
    etcd_members_string: node['kubernetes']['etcd']['members'].join(','),
    host_ip: node['ipaddress'],
    domain: node['skydns']['domain_name'] + '.' + node['skydns']['tld']
  )
  notifies :restart, 'service[skydns]', :immediately
end

service 'skydns' do
  action [:enable, :start]
end
