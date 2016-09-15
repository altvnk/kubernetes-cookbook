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
default['etcd']['client_port'] = '4001'
# iterate through members to create reusable cluster_url string
if Chef::Config[:solo]
  cluster_url = 'default=http://127.0.0.1' + ':' + default['etcd']['peer_port']
  kubernetes_etcd_url = 'http://127.0.0.1' + ':' + defaule['etcd']['client_port']
else
  etcd_members = []
  cluster_url = ''
  kubernetes_etcd_url = ''
  AttributeSearch.search(:node, 'runlist:*kubernetes:\:\etcd*') do |s|
    etcd_members << s[:fqdn]
  end
  etcd_members.each_with_index do |node_string, idx|
    cluster_url += if idx < (etcd_members.size - 1)
                     node_string + '=http://' + node_string + ':' + default['etcd']['peer_port'] + ','
                   else
                     node_string + '=http://' + node_string + ':' + default['etcd']['peer_port']
                   end
    kubernetes_etcd_url += if idx < (etcd_members.size - 1)
                             'http://' + node_string + ':' + default['etcd']['client_port'] + ','
                           else
                             'http://' + node_string + ':' + default['etcd']['client_port']
                           end
  end
end
#add cluster_url as attribute, globally available
default['etcd']['cluster_url'] = cluster_url

#kubernetes attributes
default['kubernetes']['cluster_ip_range'] = '10.0.0.1/24'
default['kubernetes']['etcd_servers'] = kubernetes_etcd_url
default['kubernetes']['insecure_api_port'] = '8080'
#iterate kube_apiservers to create apiserver_url string
if Chef::Config[:solo]
  apiserver_url = 'http://127.0.0.1' + ':' + default['kubernetes']['insecure_api_port']
else
  api_servers = []
  apiserver_url = ''
  AttributeSearch.search(:node, 'runlist:*kubernetes:\:\master*') do |s|
    api_servers << s[:fqdn]
  end
  api_servers.each_with_index do |node_string, idx|
    apiserver_url += if idx < (api_servers.size - 1)
                     node_string + 'http://' + node_string + ':' + default['kubernetes']['insecure_api_port'] + ','
                   else
                     node_string + 'http://' + node_string + ':' + default['kubernetes']['insecure_api_port']
                   end
  end
end
#add apiserver_url as attribute, globally available
default['kubernetes']['apiserver_url'] = apiserver_url
