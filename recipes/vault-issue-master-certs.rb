#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: vault-issue-master-certs
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'issue-k8s-master-certs' do
  api_server "https://#{node['vault']['pki'][rand(node['vault']['pki_num'])]}:8200"
  initial_token_data_bag_name 'vault_keys'
  initial_token_data_bag_item_name 'vault_token'
  mount_path 'k8s-infra'
  kubernetes_key_file '/etc/k8s-certs/key.pem'
  kubernetes_certificate_file '/etc/k8s-certs/cert.pem'
  kubernetes_certificate_common_name node['fqdn']
  kubernetes_certificate_alt_names 'kubernetes,kubernetes.local'
  kubernetes_certificate_ip_sans "#{node['ipaddress']},10.100.0.1,10.0.0.1"
  action :issue_kubernetes_certificates
end
