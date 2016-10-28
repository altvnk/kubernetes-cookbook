#
# Cookbook Name:: kubernetes
# Recipe:: vault-conf-pki
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'

if !File.file?('/etc/vault_ca/ca.pem')
  # create and configure root CA
  execute 'mount_root_pki' do
    command 'vault mount -path=k8s-infra -description="K8S cluster Root CA" -max-lease-ttl=87600h pki'
  end

  execute 'create_root_ca' do
    command 'vault write k8s-infra/root/generate/internal common_name="K8S cluster Root CA" ttl=87600h key_bits=4096 exclude_cn_from_sans=true'
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
      request = shell_out('vault write k8s-infra-interm/intermediate/generate/internal common_name="K8S cluster Intermediate CA" ttl=26280h key_bits=4096 exclude_cn_from_sans=true').stdout
      csr_text = request.split('csr')[1].strip
      sign_request = shell_out("vault write k8s-infra-interm/root/sign-intermediate csr=#{csr_text} common_name='K8S cluster Intermediate CA ttl=8760h").stdout
      
    end
  end
  ruby_block 'create_root_ca' do
    block do
      Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
      raw_cert_data = shell_out('vault write k8s-infra/root/generate/internal common_name="K8S cluster Root CA" ttl=87600h key_bits=4096 exclude_cn_from_sans=true').stdout

    end
  end
end