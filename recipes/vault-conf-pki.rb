#
# Cookbook Name:: kubernetes
# Recipe:: vault-conf-pki
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'configure-pki' do
  api_server "https://#{node['ipaddress']}:8200"
  initial_token_data_bag_name 'vault_keys'
  initial_token_data_bag_item_name 'vault_token'
  ca_data_bag_name 'vault_ca'
  mount_path 'k8s-infra'
  root_ca_common_name 'K8S cluster Root CA'
  intermediate_ca_common_name 'K8S cluster Intermediate CA'
  trusted_ca_file '/etc/pki/ca-trust/source/anchors/vault_ca.pem'
  trusted_ca_data_bag_item_name 'ca'
  csr_file '/etc/pki/ca-trust/source/anchors/vault_interm.csr'
  intermediate_certificate_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  intermediate_certificate_data_bag_item_name 'interm'
  action :configure_pki
end
