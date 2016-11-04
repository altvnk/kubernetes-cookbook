#
# Cookbook Name:: kubernetes
# Recipe:: vault
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'install' do
  package_url 'https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip'
  cluster_name 'k8s_vault'
  server_config_file '/etc/vault/vault.hcl'
  server_key_file '/etc/vault/key.pem'
  server_certificate_file '/etc/vault/cert.pem'
  trusted_server_certificate_file '/etc/pki/ca-trust/source/anchors/vault_cert.pem'
  action :install
end
