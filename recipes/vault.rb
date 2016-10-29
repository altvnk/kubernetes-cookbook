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

if !File.exist?('/etc/vault/key.pem')
  openssl_rsa_key '/etc/vault/key.pem' do
    key_length 2048
  end
end

if !File.exist?('/etc/vault/cert.pem')
  openssl_x509 '/etc/vault/cert.pem' do
    common_name node['fqdn']
    key_file '/etc/vault/key.pem'
    org 'K8s Infra'
    org_unit 'Lab'
    country 'US'
    subject_alt_name ['IP:' + node['ipaddress']]
    expire 1825
  end
end

if File.exist?('/etc/vault/key.pem') && File.exist?('/etc/vault/cert.pem')
  file '/etc/pki/ca-trust/source/anchors/cert.pem' do
    only_if { ::File.exist?('/etc/vault/cert.pem') }
    mode 0755
    content ::File.open('/etc/vault/cert.pem').read
    action :create
  end

  execute 'update trust' do
    command '/usr/bin/update-ca-trust'
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
