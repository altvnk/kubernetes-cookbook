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
  not_if { ::File.exist?('/usr/local/bin/consul') }
  into '/usr/local/bin'
end

zipfile "#{Chef::Config[:file_cache_path]}/consul_web_ui.zip" do
  not_if { ::File.exist?('/var/lib/consul/web/index.html') }
  into '/var/lib/consul/web'
end

consul_join_string = ''
node['consul']['members'].each do |member|
  consul_join_string += ' -join=' + member
end

template '/etc/systemd/system/consul.service' do
  mode '0640'
  source 'consul.erb'
  variables(
    node_addr: node['ipaddress'],
    join_string: consul_join_string
  )
end

service 'consul' do
  action [:enable, :start]
end
