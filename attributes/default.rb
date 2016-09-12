#
# Cookbook Name:: kubernetes
#
# Copyright (C) 2016 Alex Litvinenko
#
# All rights reserved - Do Not Redistribute
#

class AttributeSearch
  extend Chef::DSL::DataQuery
end

default['docker']['version'] = '1.12.1'
default['docker']['storage_driver'] = 'overlay'

# etcd attributes
default['etcd']['peer_port'] = '2380'
# iterate through members to create reusable cluster_url string
if Chef::Config[:solo]
  default['etcd']['cluster_url'] = 'default=http://127.0.0.1' + ':' + default['etcd']['peer_port']
else
  AttributeSearch.search(:node, 'recipes:kubernetes\:\:etcd') do |s|
    default['etcd']['members'] << s[:fqdn]
  end
  default['etcd']['members'].each_with_index do |node_name, idx|
    if idx < (default['etcd']['members'].size - 1)
      default['etcd']['cluster_url'] += node_name + '=http://' + node_name + ':' + default['etcd']['peer_port'] + ','
    else
      default['etcd']['cluster_url'] += node_name + '=https://' + node_name + ':' + default['etcd']['peer_port']
    end
  end
end
