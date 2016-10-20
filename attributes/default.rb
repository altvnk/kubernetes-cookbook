#
# Cookbook Name:: kubernetes
#
# Copyright (C) 2016 Alex Litvinenko
#
# All rights reserved - Do Not Redistribute
#

# override chef search to use from attribute files
class AttributeSearch
  extend Chef::DSL::DataQuery
end

# docker attributes
default['docker']['version']        = '1.12.1'
default['docker']['storage_driver'] = 'overlay'

# etcd attributes
default['kubernetes']['etcd']['clientport']       = '2379'
default['kubernetes']['etcd']['peerport']         = '2380'
default['kubernetes']['etcd']['basedir']          = '/var/lib/etcd'
default['kubernetes']['etcd']['token']            = 'initialtoken'
default['kubernetes']['etcd']['initial']          = []
default['kubernetes']['etcd']['members']          = []

default['kubernetes']['etcd']['peer']['ca']       = nil
default['kubernetes']['etcd']['peer']['cert']     = nil
default['kubernetes']['etcd']['peer']['key']      = nil

default['kubernetes']['etcd']['client']['ca']     = nil
default['kubernetes']['etcd']['client']['cert']   = nil
default['kubernetes']['etcd']['client']['key']    = nil

# kubernetes master attributes
default['kubernetes']['apiserver']['insecure_port'] = '8080'
default['kubernetes']['apiserver']['cluster_url']   = []

AttributeSearch.search(:node, 'run_list:*etcd*') do |node|
  default['kubernetes']['etcd']['initial'] << "#{node['fqdn']}=http://#{node['ipaddress']}:#{default['kubernetes']['etcd']['peerport']}"
  default['kubernetes']['etcd']['members'] << "http://#{node['ipaddress']}:#{default['kubernetes']['etcd']['clientport']}"
end

AttributeSearch.search(:node, 'run_list:*master*') do |node|
  default['kubernetes']['apiserver']['cluster_url'] << "http://#{node['ipaddress']}:#{default['kubernetes']['apiserver']['insecure_port']}"
end

# chef-client attributes
default['chef_client']['interval'] = 300
