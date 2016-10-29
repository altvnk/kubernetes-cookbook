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
  token_databag_item = begin
                         data_bag_item('vault_keys', 'vault_token')
                       rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                         nil
                       end

  if !token_databag_item.nil?

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
        shell_out("vault auth #{token}")
        ca_raw = shell_out('vault write --format=json k8s-infra/root/generate/internal common_name="K8S cluster Root CA" ttl=87600h key_bits=4096 exclude_cn_from_sans=true').stdout
        ca_data = JSON.parse(ca_raw)
        File.write('/etc/pki/ca-trust/source/anchors/vault_ca.pem', ca_data['data']['certificate'])
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
        File.write('/etc/pki/ca-trust/source/anchors/vault_interm.csr', csr_text['data']['csr'])
        interm_cert = shell_out("vault write -format=json k8s-infra/root/sign-intermediate csr=@/etc/pki/ca-trust/source/anchors/vault_interm.csr common_name=\"K8S cluster Intermediate CA\" ttl=26280h").stdout
        interm_cert_data = JSON.parse(interm_cert)
        File.write('/etc/pki/ca-trust/source/anchors/k8s-infra-interm.crt', interm_cert_data['data']['certificate'])
      end
    end

    execute 'configure_intermediate_ca_signed_cert' do
      command 'vault write k8s-infra-interm/intermediate/set-signed certificate=@/etc/pki/ca-trust/source/anchors/k8s-infra-interm.crt'
    end

    execute 'configure_intermediate_ca_urls' do
      command "vault write k8s-infra-interm/config/urls issuing_certificates=\"https://#{node['ipaddress']}:8200/v1/k8s-infra-interm/ca\" crl_distribution_points=\"https://#{node['ipaddress']}:8200/v1/k8s-infra-interm/crl\""
    end

    # configure cert roles
    execute 'configure_etcd_role' do
      command 'vault write k8s-infra-interm/roles/server key_bits=2048 max_ttl=8760h allow_any_name=true'
    end

    execute 'update_trust' do
      command '/usr/bin/update-ca-trust'
    end
  end
else
  # put CA certificate to databag for distribution
  ca_data = {
      'id' => 'ca',
      'ca_cert' => File.open('/etc/pki/ca-trust/source/anchors/vault_ca.pem').read
  }
  interm_data = {
      'id' => 'interm',
      'interm_cert' => File.open('/etc/pki/ca-trust/source/anchors/k8s-infra-interm.crt').read
  }
  cert_databag = begin
    data_bag('vault_ca')
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
    nil
  end

  cert_databag_item = begin
    data_bag_item('vault_ca', 'ca')
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
    nil
  end

  interm_databag_item = begin
    data_bag_item('vault_ca', 'interm')
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
    nil
  end

  if cert_databag.nil?
    cert_databag = Chef::DataBag.new
    cert_databag.name('vault_ca')
    cert_databag.create
  end

  if cert_databag_item.nil?
    cert_databag_item = Chef::DataBagItem.new
    cert_databag_item.raw_data = ca_data
    cert_databag_item.data_bag('vault_ca')
    cert_databag_item.create
    cert_databag_item.save
  end

  if interm_databag_item.nil?
    interm_databag_item = Chef::DataBagItem.new
    interm_databag_item.raw_data = interm_data
    interm_databag_item.data_bag('vault_ca')
    interm_databag_item.create
    interm_databag_item.save
  end

end
