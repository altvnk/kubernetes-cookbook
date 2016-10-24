#
# Cookbook Name:: kubernetes
# Recipe:: consul
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

directory '/var/lib/consul/web' do
  recursive true
end

remote_file 'consul package' do
  path "#{Chef::Config[:file_cache_path]}/consul_package.zip"
  source 'https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip'
end
remote_file 'consul UI package' do
  path "#{Chef::Config[:file_cache_path]}/consul_web_ui.zip"
  source 'https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_web_ui.zip'
end

zipfile "#{Chef::Config[:file_cache_path]}/consul_package.zip" do
  into '/usr/local/bin'
end

zipfile "#{Chef::Config[:file_cache_path]}/consul_web_ui.zip" do
  into '/var/lib/consul/web'
end

template '/etc/systemd/system/consul.service' do
  mode '0640'
  source 'consul.erb'
end

service 'consul' do
  action[:enable, :start]
end
