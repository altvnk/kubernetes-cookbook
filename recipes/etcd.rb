#
# Cookbook Name:: kubernetes
# Recipe:: etcd
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

etcd_installation 'default' do
  action :create
end

etcd_service 'etcd' do
  node_name node['hostname']
  advertise_client_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['clientport']
  listen_client_urls 'http://0.0.0.0:' + node['kubernetes']['etcd']['clientport']
  initial_advertise_peer_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['peerport']
  listen_peer_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['peerport']
  initial_cluster_token node['kubernetes']['etcd']['token']
  initial_cluster node['kubernetes']['etcd']['initial'].join(',')
  action :start
end
