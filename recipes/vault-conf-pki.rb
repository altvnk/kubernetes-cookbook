#
# Cookbook Name:: kubernetes
# Recipe:: vault-conf-pki
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'

directory '/etc/vault_ca' do
  recursive true
end

if !File.file?('/etc/pki/ca-trust/source/anchors/vault_ca.pem')
  # auth with vault
  token = data_bag_item('vault_keys', 'vault_token')['token']
  execute 'vault_auth' do
    command "vault auth #{token}"
  end

  # create and configure root CA TODO: add mount checks
  execute 'mount_root_pki' do
    command 'vault mount -path=k8s-infra -description="K8S cluster Root CA" -max-lease-ttl=87600h pki'
  end

  ruby_block 'create_root_ca' do
    block do
      ca_raw = shell_out('vault write --format=json k8s-infra/root/generate/internal common_name="K8S cluster Root CA" ttl=87600h key_bits=4096 exclude_cn_from_sans=true').stdout
      ca_data = JSON.parse(ca_raw)
      ca_file = File.new('/etc/pki/ca-trust/source/anchors/vault_ca.pem', 'w')
      ca_file.write(ca_data['data']['certificate'])
      ca_file.close
    end
  end

  execute 'configure_root_ca_issuing_url' do
    command "vault write k8s-infra/config/urls issuing_certificates=\"https://#{node['ipaddress']}:8200/v1/k8s-infra\""
  end

  # create and configure intermediate CA
  execute 'mount_intermediate_pki' do
    command 'vault mount -path=k8s-infra-interm -description="K8S cluster Intermediate CA" -max-lease-ttl=26280h pki'
  end

  ruby_block 'create_intermediate_ca' do
    block do
      csr_request = shell_out('vault write -format=json k8s-infra-interm/intermediate/generate/internal common_name="K8S cluster Intermediate CA" ttl=26280h key_bits=4096 exclude_cn_from_sans=true').stdout
      csr_text = JSON.parse(csr_request)
      shell_out("vault write -format=json k8s-infra-interm/root/sign-intermediate csr=#{csr_text['data']['csr']} common_name='K8S cluster Intermediate CA ttl=8760h").stdout
    end
  end

  execute 'configure_intermediate_ca_urls' do
    command "vault write k8s-infra-interm/config/urls issuing_certificates=\"https://#{node['ipaddress']}:8200/v1/k8s-infra-interm/ca\" crl_distribution_points=\"https://#{node['ipaddress']}:8200/v1/cuddletech_ops/crl\""
  end

  # configure cert roles
  execute 'configure_etcd_role' do
    command 'vault write k8s-infra-interm/roles/server key_bits=2048 max_ttl=8760h allow_any_name=true'
  end

  execute 'update_trust' do
    command '/usr/bin/update-ca-trust'
  end

end