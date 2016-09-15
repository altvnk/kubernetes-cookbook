#
# Cookbook Name:: kubernetes
#
# Copyright (C) 2016 Alex Litvinenko
#
# All rights reserved - Do Not Redistribute
#

#override chef search to use from attribute files
class AttributeSearch
  extend Chef::DSL::DataQuery
end

#docker attributes
default['docker']['version'] = '1.12.1'
default['docker']['storage_driver'] = 'overlay'

# etcd attributes
default['etcd']['peer_port'] = '2380'
# iterate through members to create reusable cluster_url string
if Chef::Config[:solo]
 cluster_url = 'default=http://127.0.0.1' + ':' + default['etcd']['peer_port']
else
  etcd_members = []
  cluster_url = ''
  AttributeSearch.search(:node, 'tags:etcd') do |s|
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
#add cluster_url as attribute, globally available
default['etcd']['cluster_url'] = cluster_url
