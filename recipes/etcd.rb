#
# Cookbook Name:: kubernetes
# Recipe:: etcd
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

etcd_installation 'default' do
  action :create
end

etcd_service 'etcd' do
  node_name node['hostname']
  advertise_client_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['clientport']
  listen_client_urls 'http://0.0.0.0:' + node['kubernetes']['etcd']['clientport']
  initial_advertise_peer_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['peerport']
  listen_peer_urls 'http://' + node['ipaddress'] + ':' + node['kubernetes']['etcd']['peerport']
  initial_cluster_token node['kubernetes']['etcd']['token']
  initial_cluster node['kubernetes']['etcd']['initial'].join(',')
  #  cert_file '/etc/k8s-certs/cert.pem'
  #  key_file '/etc/k8s-certs/key.pem'
  #  trusted_ca_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  #  client_cert_auth false
  #  peer_cert_file '/etc/k8s-certs/cert.pem'
  #  peer_key_file '/etc/k8s-certs/key.pem'
  #  peer_client_cert_auth false
  #  peer_trusted_ca_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  notifies :run, 'execute[daemon-reload]', :immediately
  action :start
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end
