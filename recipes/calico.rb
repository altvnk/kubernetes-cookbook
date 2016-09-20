#
# Cookbook Name:: kubernetes
# Recipe:: calico
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

# create calico and CNI conf directories
directory '/opt/cni/bin' do
  recursive true
end

directory '/etc/cni/net.d' do
  recursive true
end

# download calico binaries
remote_file 'calicoctl binary' do
  path '/usr/bin/calicoctl'
  mode '0755'
  source 'http://www.projectcalico.org/builds/calicoctl'
end

remote_file 'calico binary' do
  path '/opt/cni/bin/calico'
  mode '0755'
  source 'https://github.com/projectcalico/calico-cni/releases/download/v1.3.1/calico'
end

remote_file 'calico-ipam binary' do
  path '/opt/cni/bin/calico-ipam'
  mode '0755'
  source 'https://github.com/projectcalico/calico-cni/releases/download/v1.3.1/calico-ipam'
end

# render conf templates
template '/etc/systemd/system/calico.service' do
  mode '0640'
  source 'calico.erb'
  variables(
      etcd_members_string: node['kubernetes']['etcd']['members'].join(',')
  )
end

template '/etc/cni/net.d/10-calico.conf' do
  mode '0640'
  source 'cni.erb'
  variables(
      etcd_members_string: node['kubernetes']['etcd']['members'].join(',')
  )
end

service 'calico' do
  action [:restart]
end

service 'docker' do
  action [:restart]
end
