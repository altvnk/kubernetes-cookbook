#
# Cookbook Name:: kubernetes
#
# Copyright (C) 2016 Alex Litvinenko
#
# All rights reserved - Do Not Redistribute
#

default['docker']['version'] = '1.12.1'
default['docker']['storage_driver'] = 'overlay'

# etcd attributes
default['etcd']['peer_port'] = '2380'
# iterate through members to create reusable cluster_url string
if Chef::Config[:solo]
  default['etcd']['cluster_url'] = 'default=http://127.0.0.1' + ':' + default['etcd']['peer_port']
else
  search(:node, 'recipes:kubernetes\:\:etcd') do |s|
    default['etcd']['members'] << "#{s.fqdn}"
  end
  default['etcd']['members'].each_with_index do |node_string, idx|
    if idx < (default['etcd']['members'].size - 1)
      default['etcd']['cluster_url'] += node_string + '=http://' + node_string + ':' + default['etcd']['peer_port'] + ','
    else
      default['etcd']['cluster_url'] += node_string + '=https://' + node_string + ':' + default['etcd']['peer_port']
    end
  end
end
