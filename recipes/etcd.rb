#
# Cookbook Name:: kubernetes
# Recipe:: etcd
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
else
  etcd_service node['hostname'] do
    advertise_client_urls 'http://127.0.0.1:2379,http://127.0.0.1:4001'
    listen_client_urls 'http://0.0.0.0:2379,http://0.0.0.0:4001'
    initial_advertise_peer_urls 'http://127.0.0.1:2380'
    listen_peer_urls 'http://0.0.0.0:2380'
    initial_cluster_token 'etcd-cluster-1'
    initial_cluster node['etcd']['cluster_url']
    initial_cluster_state 'new'
    action [:create, :start]
  end
end
