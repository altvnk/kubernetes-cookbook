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
  not_if { ::File.exist?('/etc/vault/key.pem') }
  key_length 2048
end

openssl_x509 '/etc/vault/cert.pem' do
  not_if { ::File.exist?('/etc/vault/cert.pem') }
  common_name node['fqdn']
  key_file '/etc/vault/key.pem'
  org 'K8s Infra'
  org_unit 'Lab'
  country 'US'
  subject_alt_name ['IP:' + node['ipaddress']]
  expire 1825
end

if File.exist?('/etc/vault/key.pem') && File.exist?('/etc/vault/cert.pem')
  file '/etc/pki/ca-trust/source/anchors/cert.pem' do
    only_if { ::File.exist?('/etc/vault/cert.pem') }
    mode 0755
    content ::File.open('/etc/vault/cert.pem').read
    action :create
    notifies :run, 'execute[update trust]', :immediately
  end

  execute 'update trust' do
    command '/usr/bin/update-ca-trust'
    action :nothing
  end

  include_recipe 'kubernetes::vault-binaries'

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

end
