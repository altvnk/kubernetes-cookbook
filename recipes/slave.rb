#
# Cookbook Name:: kubernetes
# Recipe:: slave
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

Chef::Application.fatal!('No K8S masters! Please, set up K8S masters prior to installing slave role', 1) if node['kubernetes']['apiserver']['cluster_url'].empty?
etcd_installation 'default' do
  action :create
end
directory '/etc/kubernetes/manifests' do
  recursive true
end
kubelet_service 'kubelet' do
  api_servers node['kubernetes']['apiserver']['cluster_url'].join(',')
  config '/etc/kubernetes/manifests'
  cluster_dns '10.0.0.10'
  cluster_domain 'kubernetes.local'
  network_plugin 'cni'
  network_plugin_dir '/etc/cni/net.d'
  action %w(create start)
end
package 'ethtool'
group 'docker' do
  members ['kubernetes']
end
service 'kubelet' do
  action [:restart]
end

include_recipe 'kubernetes::calico-policy-controller'
