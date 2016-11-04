#
# Cookbook Name:: kubernetes
# Recipe:: client_wrapper
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'chef-client::systemd_service'

node.run_list.add('recipe[kubernetes::consul]') if node['tags'].include?('etcd') || node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-binaries]') unless node['tags'].include?('etcd')
node.run_list.add('recipe[kubernetes::vault]') if node['tags'].include?('etcd') || node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-init]') if node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-unseal]') if node['tags'].include?('etcd') || node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-conf-pki]') if node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-trust-ca]')
node.run_list.add('recipe[kubernetes::renew-vault-certs]') if node['tags'].include?('etcd') || node['tags'].include?('etcd-init')
node.run_list.add('recipe[kubernetes::vault-issue-k8s-certs]') unless node['tags'].include?('etcd') || node['tags'].include?('etcd-init') || node['tags'].include?('master')
node.run_list.add('recipe[kubernetes::vault-issue-master-certs]') if node['tags'].include?('master')
node.run_list.add('role[etcd]') if node['tags'].include?('etcd') || node['tags'].include?('etcd-init')

node.run_list.add('role[master]') if node['tags'].include? 'master'
node.run_list.add('role[slave]') if node['tags'].include? 'slave'
node.run_list.add('recipe[resolver::default]') if node['skydns_enabled']
node.run_list.add('recipe[kubernetes::post-setup]') if node['skydns_enabled']
