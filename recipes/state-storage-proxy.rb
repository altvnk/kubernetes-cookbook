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
  proxy true
  listen_client_urls 'http://127.0.0.1:' + node['kubernetes']['etcd']['clientport']
  listen_peer_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['peerport']
  initial_cluster node['kubernetes']['etcd']['initial'].join(',')
  action :start
end
