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
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/etc/cni/net.d' do
  recursive true
end

directory '/etc/calico' do
  recursive true
end

# download calico binaries
remote_file 'calicoctl binary' do
  path '/usr/bin/calicoctl'
  mode '0777'
  source 'http://www.projectcalico.org/builds/calicoctl'
end

remote_file 'calico binary' do
  path '/opt/cni/bin/calico'
  mode '0777'
  source 'https://github.com/projectcalico/calico-cni/releases/download/v1.3.1/calico'
end

remote_file 'calico-ipam binary' do
  path '/opt/cni/bin/calico-ipam'
  mode '0777'
  source 'https://github.com/projectcalico/calico-cni/releases/download/v1.3.1/calico-ipam'
end

remote_file "#{Chef::Config[:file_cache_path]}/cni-v0.3.0.tgz" do
  mode '0777'
  source 'https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz'
end

execute 'extract_binaries' do
  command "tar -xzvf #{Chef::Config[:file_cache_path]}/cni-v0.3.0.tgz -C /opt/cni/bin"
end

# render conf templates
template '/etc/systemd/system/calico.service' do
  mode '0640'
  source 'calico.erb'
end

template '/etc/cni/net.d/10-calico.conf' do
  mode '0666'
  source 'cni.erb'
  variables(
    etcd_members_string: node['kubernetes']['etcd']['members'].join(','),
    k8s_apiserver: node['kubernetes']['apiserver']['name_cluster_url'][0]
  )
end

template '/etc/calico/calico-env' do
  mode '0666'
  source 'calico-env.erb'
  variables(
    etcd_members_string: node['kubernetes']['etcd']['members'].join(',')
  )
end

service 'calico' do
  action [:enable, :start]
end
