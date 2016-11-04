#
# Cookbook Name:: kubernetes
# Recipe:: calico
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

kube_proxy 'kubeproxy' do
  master node['kubernetes']['apiserver']['cluster_url'][0]
  kubeconfig '/var/lib/kubelet/kubeconfig'
  action [:create, :start]
end
