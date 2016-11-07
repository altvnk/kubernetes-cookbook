#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: renew-vault-certs
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'kubernetes::vault-issue-k8s-certs'

vault 'renew-vault-certs' do
  kubernetes_certificate_file '/etc/k8s-certs/cert.pem'
  kubernetes_key_file '/etc/k8s-certs/key.pem'
  server_key_file '/etc/vault/key.pem'
  server_certificate_file '/etc/vault/cert.pem'
  action :renew_server_certificates
  notifies :restart, 'service[vault]', :immediately
end

service 'vault' do
  action :nothing
end

include_recipe 'kubernetes::vault-unseal'
