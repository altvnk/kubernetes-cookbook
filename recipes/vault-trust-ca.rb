#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: vault-trust-ca
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'trust-ca' do
  api_server "https://#{node['consul']['members'][rand(node['consul']['members_num'])]}:8200"
  ca_data_bag_name 'vault_ca'
  trusted_ca_file '/etc/pki/ca-trust/source/anchors/vault_ca.pem'
  trusted_ca_data_bag_item_name 'ca'
  intermediate_certificate_file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem'
  intermediate_certificate_data_bag_item_name 'interm'
  action :trust_ca
end
