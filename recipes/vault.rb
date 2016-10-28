#
# Cookbook Name:: kubernetes
# Recipe:: vault
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

directory '/etc/vault' do
  recursive true
end

openssl_rsa_key '/etc/vault/key.pem' do
  key_length 2048
end

openssl_x509 '/etc/vault/cert.pem' do
  common_name node['fqdn']
  key_file '/etc/vault/key.pem'
  org 'K8s Infra'
  org_unit 'Lab'
  country 'US'
  subject_alt_name ['IP:' + node['ipaddress']]
  expire 1825
end

file '/etc/pki/ca-trust/source/anchors/cert.pem' do
  mode 0755
  content ::File.open("/etc/vault/cert.pem").read
  action :create
end

execute 'update trust' do
  command '/usr/bin/update-ca-trust'
end

remote_file 'vault package' do
  path "#{Chef::Config[:file_cache_path]}/vault_package.zip"
  source 'https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip'
end

zipfile "#{Chef::Config[:file_cache_path]}/vault_package.zip" do
  not_if { ::File.exist?('/usr/local/bin/vault') }
  into '/usr/local/bin'
end

template '/etc/systemd/system/vault.service' do
  mode '0640'
  source 'vault.erb'
end

template '/etc/vault/vault.hcl' do
  mode '0640'
  source 'vault-config.erb'
  variables(
    node_addr: node['ipaddress']
  )
end

service 'vault' do
  action [:enable, :start]
end
