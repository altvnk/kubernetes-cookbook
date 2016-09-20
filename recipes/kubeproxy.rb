#
# Cookbook Name:: kubernetes
# Recipe:: calico
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

kube_proxy 'kubeproxy' do
  action [:create, :start]
end
