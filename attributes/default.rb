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
# toggles
default['skydns_enabled'] = true

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
default['kubernetes']['etcd']['nodes']            = []
default['kubernetes']['etcd']['hostname_members'] = []

default['kubernetes']['etcd']['peer']['ca']       = '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
default['kubernetes']['etcd']['peer']['cert']     = '/etc/k8s-certs/cert.pem'
default['kubernetes']['etcd']['peer']['key']      = '/etc/k8s-certs/key.pem'

default['kubernetes']['etcd']['client']['ca']     = '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
default['kubernetes']['etcd']['client']['cert']   = '/etc/k8s-certs/cert.pem'
default['kubernetes']['etcd']['client']['key']    = '/etc/k8s-certs/key.pem'

# kubernetes master attributes
default['kubernetes']['apiserver']['insecure_port'] = '8080'
default['kubernetes']['apiserver']['secure_port']   = '6443'
default['kubernetes']['apiserver']['cluster_url']   = []
default['kubernetes']['apiserver']['name_cluster_url'] = []

AttributeSearch.search(:node, 'run_list:*etcd*') do |node|
  default['kubernetes']['etcd']['initial'] << "#{node['hostname']}=http://#{node['ipaddress']}:#{default['kubernetes']['etcd']['peerport']}"
  default['kubernetes']['etcd']['members'] << "http://#{node['ipaddress']}:#{default['kubernetes']['etcd']['clientport']}"
  default['kubernetes']['etcd']['hostname_members'] << "http://#{node['hostname']}:#{default['kubernetes']['etcd']['clientport']}"
  default['kubernetes']['etcd']['nodes'] << node['ipaddress']
end

AttributeSearch.search(:node, 'run_list:*master*') do |node|
  default['kubernetes']['apiserver']['cluster_url'] << "https://#{node['ipaddress']}:#{default['kubernetes']['apiserver']['secure_port']}"
  default['kubernetes']['apiserver']['name_cluster_url'] << "https://#{node['fqdn']}:#{default['kubernetes']['apiserver']['secure_port']}"
end

# chef-client attributes
default['chef_client']['interval'] = 180
default['chef_client']['splay'] = 0

# consul attributes
default['consul']['members'] = []
AttributeSearch.search(:node, 'run_list:*consul*') do |node|
  default['consul']['members'] << node['ipaddress']
end
default['consul']['members_num'] = default['consul']['members'].length

# vault attributes
default['vault']['pki'] = []
AttributeSearch.search(:node, 'run_list:*consul*') do |node|
  default['vault']['pki'] << node['ipaddress']
end
default['vault']['pki_num'] = default['vault']['pki'].length

# SkyDNS attributes
default['skydns']['image_name']      = 'skynetservices/skydns:latest'
default['skydns']['tld']             = 'local'
default['skydns']['domain_name']     = 'k8s'
default['skydns']['nameservers']     = '"8.8.8.8:53", "8.8.4.4:53"'

# resolver conf
default['resolver']['search']       = default['skydns']['domain_name'] + '.' + default['skydns']['tld']
default['resolver']['nameservers']  = default['kubernetes']['etcd']['nodes']
