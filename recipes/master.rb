#
# Cookbook Name:: kubernetes
# Recipe:: master
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

Chef::Application.fatal!('No ETCD nodes found! Please, set up ETCD cluster prior to installing master role', 1) if node['kubernetes']['etcd']['members'].empty?
remote_file 'kubectl binary' do
  path '/usr/bin/kubectl'
  mode '0755'
  source 'https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl'
  checksum 'ec6941a5ff14ddd5044f11f369a8e0946f00201febc73282554f2150aad5bc06'
end
directory '/etc/kubernetes/manifests' do
  mode 0755
  recursive true
end

directory '/var/lib/kubelet' do
  mode 0755
  recursive true
end

template '/var/lib/kubelet/kubeconfig' do
  mode 0755
  source 'kubeconfig.erb'
  variables(
    cluster_url: node['kubernetes']['apiserver']['name_cluster_url'][0],
    base64encodedcert: '/etc/k8s-certs/cert.pem',
    base64encodedkey: '/etc/k8s-certs/key.pem',
    base64encodedcacert: '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  )
  notifies :restart, 'service[kube-apiserver]', :immediately
end

# TODO: use vault for secrets generation
file '/var/lib/kubelet/known_users.csv' do
  content 'kubeadmin,kubeadmin,kube1'
  mode 0666
end

file '/var/lib/kubelet/tokens.csv' do
  content 'admin,admin,admin'
  mode 0666
end

kube_apiserver 'master' do
  only_if { ::File.file?('/etc/k8s-certs/cert.pem') }
  admission_control 'NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota'
  service_cluster_ip_range '10.0.0.1/24'
  etcd_servers node['kubernetes']['etcd']['members'].join(',')
  insecure_bind_address '127.0.0.1' # for convenience
  insecure_port node['kubernetes']['apiserver']['insecure_port']
  allow_privileged true
  enable_swagger_ui true
  service_account_key_file '/etc/k8s-certs/key.pem'
  basic_auth_file '/var/lib/kubelet/known_users.csv'
  token_auth_file '/var/lib/kubelet/tokens.csv'
  client_ca_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  kubelet_certificate_authority '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  tls_cert_file '/etc/k8s-certs/cert.pem'
  tls_private_key_file '/etc/k8s-certs/key.pem'
  action [:create, :start]
  notifies :run, 'execute[daemon-reload]', :immediately
  notifies :restart, 'service[kube-apiserver]', :immediately
end

kube_scheduler 'default' do
  only_if { ::File.file?('/etc/k8s-certs/cert.pem') }
  master 'http://127.0.0.1:8080'
  leader_elect 'true'
  action [:create, :start]
  notifies :run, 'execute[daemon-reload]', :immediately
  notifies :restart, 'service[kube-scheduler]', :immediately
end

kube_controller_manager 'default' do
  only_if { ::File.file?('/etc/k8s-certs/cert.pem') }
  master 'http://127.0.0.1:8080'
  leader_elect true
  kubeconfig '/var/lib/kubelet/kubeconfig'
  root_ca_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  service_account_private_key_file '/etc/k8s-certs/key.pem'
  action [:create, :start]
  notifies :run, 'execute[daemon-reload]', :immediately
  notifies :restart, 'service[kube-controller-manager]', :immediately
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'kube-apiserver' do
  only_if { ::File.file?('/etc/systemd/system/kube-apiserver.service') }
  action :nothing
end

service 'kube-controller-manager' do
  only_if { ::File.file?('/etc/systemd/system/kube-controller-manager.service') }
  action :nothing
end

service 'kube-scheduler' do
  only_if { ::File.file?('/etc/systemd/system/kube-scheduler.service') }
  action :nothing
end

include_recipe 'kubernetes::calico-policy-controller'
