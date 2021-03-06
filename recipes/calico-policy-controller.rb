#
# Cookbook Name:: kubernetes
# Recipe:: calico-policy-controller
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

template '/etc/kubernetes/manifests/calico-policy-controller.yml' do
  mode '0666'
  source 'calico-policy-controller.erb'
  variables(
    etcd_endpoints: node['kubernetes']['etcd']['members'].join(','),
    kubemaster_url: node['kubernetes']['apiserver']['name_cluster_url'].join(',')
  )
end
