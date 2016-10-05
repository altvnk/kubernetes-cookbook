#
# Cookbook Name:: kubernetes
# Recipe:: master
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

Chef::Application.fatal!('No ETCD nodes found! Please, set up ETCD cluster prior to installing master role', 1) if node['kubernetes']['etcd']['members'].empty?
remote_file 'kubectl binary' do
  path '/usr/bin/kubectl'
  mode '0755'
  source 'https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl'
  checksum 'ec6941a5ff14ddd5044f11f369a8e0946f00201febc73282554f2150aad5bc06'
end
directory '/etc/kubernetes/manifests' do
  recursive true
end

kube_apiserver 'master' do
  service_cluster_ip_range '10.0.0.1/24'
  etcd_servers node['kubernetes']['etcd']['members'].join(',')
  insecure_bind_address '0.0.0.0' # for convenience
  insecure_port node['kubernetes']['apiserver']['insecure_port']
  allow_privileged true
  action [:create, :start]
end

kube_scheduler 'default' do
  master 'http://127.0.0.1:8080'
  leader_elect 'true'
  action [:create, :start]
end

kube_controller_manager 'default' do
  master 'http://127.0.0.1:8080'
  leader_elect true
  action [:create, :start]
end

include_recipe 'kubernetes::calico-policy-controller'
