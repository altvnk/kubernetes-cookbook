#
# Cookbook Name:: kubernetes
# Recipe:: slave
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

Chef::Application.fatal!('No K8S masters! Please, set up K8S masters prior to installing slave role', 1) if node['kubernetes']['apiserver']['cluster_url'].empty?
etcd_installation 'default' do
  action :create
end
directory '/etc/kubernetes/manifests' do
  mode 0755
  recursive true
end

directory '/var/lib/kubelet' do
  mode 0755
  recursive true
end

remote_file 'kubectl binary' do
  path '/usr/bin/kubectl'
  mode '0755'
  source 'https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl'
  checksum 'ec6941a5ff14ddd5044f11f369a8e0946f00201febc73282554f2150aad5bc06'
end

template '/var/lib/kubelet/kubeconfig' do
  mode 0755
  source 'kubeconfig.erb'
  variables(
    cluster_url: node['kubernetes']['apiserver']['name_cluster_url'][0],
    base64encodedcert: '/etc/k8s-certs/cert.pem',
    base64encodedkey: '/etc/k8s-certs/key.pem',
    base64encodedcacert: '/etc/pki/ca-trust/source/anchors/vault_ca.pem'
  )
end

kubelet_service 'kubelet' do
  api_servers node['kubernetes']['apiserver']['cluster_url'].join(',')
  allow_privileged true
  kubeconfig '/var/lib/kubelet/kubeconfig'
  require_kubeconfig true
  cluster_dns '10.0.0.10'
  cluster_domain 'kubernetes.local'
  network_plugin 'cni'
  network_plugin_dir '/etc/cni/net.d'
  tls_cert_file '/etc/k8s-certs/cert.pem'
  tls_private_key_file '/etc/k8s-certs/key.pem'
  action %w(create start)
end
package 'ethtool'
group 'docker' do
  members ['kubernetes']
end

include_recipe 'kubernetes::calico-policy-controller'
