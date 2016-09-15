#
# Cookbook Name:: kubernetes
# Recipe:: master
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

if Chef::Config[:solo]
  etcd_service 'default' do
    advertise_client_urls 'http://127.0.0.1:2379,http://127.0.0.1:4001'
    listen_client_urls 'http://0.0.0.0:2379,http://0.0.0.0:4001'
    initial_advertise_peer_urls 'http://127.0.0.1:2380'
    listen_peer_urls 'http://0.0.0.0:2380'
    initial_cluster_token 'etcd-cluster-1'
    initial_cluster node['etcd']['cluster_url']
    initial_cluster_state 'new'
    action [:create, :start]
  end
  kube_apiserver 'default' do
    service_cluster_ip_range node['kubernetes']['cluster_ip_range']
    etcd_servers node['kubernetes']['etcd_servers']
    insecure_bind_address '0.0.0.0'
    action [:create, :start]
  end
  kube_scheduler 'default' do
    action [:create, :start]
  end
  kube_controller_manager 'default' do
    action [:create, :start]
  end
else
  Chef::Application.fatal!("No ETCD nodes found! Please, set up ETCD cluster prior to installing master role", 1) if node['etcd']['cluster_url'].length == 0
  kube_apiserver node['fqdn'] do
    service_cluster_ip_range node['kubernetes']['cluster_ip_range']
    etcd_servers node['kubernetes']['etcd_servers']
    insecure_bind_address '0.0.0.0'
    action [:create, :start]
  end
  kube_scheduler node['fqdn'] do
    action [:create, :start]
  end
  kube_controller_manager node['fqdn'] do
    action [:create, :start]
  end
end