#
# Cookbook Name:: kubernetes
# Recipe:: etcd
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

# iterate through members to create reusable cluster_url string
if Chef::Config[:solo]
  cluster_url = 'default=http://127.0.0.1' + ':' + node['etcd']['peer_port']
else
  etcd_members = []
  cluster_url = ''
  search(:node, 'tags:etcd') do |s|
    etcd_members << s[:fqdn]
  end
  etcd_members.each_with_index do |node_string, idx|
    cluster_url += if idx < (etcd_members.size - 1)
                     node_string + '=http://' + node_string + ':' + node['etcd']['peer_port'] + ','
                   else
                     node_string + '=http://' + node_string + ':' + node['etcd']['peer_port']
                   end
  end
end

if Chef::Config[:solo]
  etcd_service 'default' do
    advertise_client_urls 'http://127.0.0.1:2379,http://127.0.0.1:4001'
    listen_client_urls 'http://0.0.0.0:2379,http://0.0.0.0:4001'
    initial_advertise_peer_urls 'http://127.0.0.1:2380'
    listen_peer_urls 'http://0.0.0.0:2380'
    initial_cluster_token 'etcd-cluster-1'
    initial_cluster cluster_url
    initial_cluster_state 'new'
    action [:create, :start]
  end
else
  etcd_service node['fqdn'] do
    advertise_client_urls 'http://' + node['ipaddress'] + ':2379,http://' + node['ipaddress'] + ':4001'
    listen_client_urls 'http://0.0.0.0:2379,http://0.0.0.0:4001'
    initial_advertise_peer_urls 'http://' + node['ipaddress'] + ':2380'
    listen_peer_urls 'http://0.0.0.0:2380'
    initial_cluster_token 'etcd-cluster-1'
    initial_cluster cluster_url
    initial_cluster_state 'new'
    action [:create, :start]
  end
end
