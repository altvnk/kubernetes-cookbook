#
# Cookbook Name:: kubernetes
# Recipe:: addons
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

template '/etc/kubernetes/manifests/kube-dns.yml' do
  mode '0666'
  source 'kube-dns.erb'
  variables(
    kubemaster_url: node['kubernetes']['apiserver']['cluster_url'][0]
  )
end

template '/etc/kubernetes/manifests/kubernetes-dashboard.yml' do
  mode '0666'
  source 'kubernetes-dashboard.erb'
  variables(
    kubemaster_url: node['kubernetes']['apiserver']['cluster_url'][0]
  )
end
