#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: vault-conf-pki
#
# Copyright (C) 2016 Oleksii Slobodyskyi
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'

if !File.file?('/etc/k8s-certs/key.pem')
  # create role for kubernetes
  execute 'create_kubernetes_role' do
    command 'vault write k8s-infra/roles/kubernetes max_ttl=87600h key_bits=4096 allow_any_name=true'
  end

  directory '/etc/k8s-certs' do
    mode '0700'
    action :create
  end

  ruby_block 'create_kubernetes_certs' do
    block do
      require 'json'

      stdout = shell_out("vault write -format=json k8s-infra/issue/kubernetes common_name=\"#{node['fqdn']}\" ip_sans=\"#{node['ipaddress']}\" ttl=8760h format=pem").stdout
      parsed_stdout = JSON.parse(stdout)

      File.write('/etc/k8s-certs/cert.pem', parsed_stdout['data']['certificate'])
      File.write('/etc/k8s-certs/key.pem', parsed_stdout['data']['private_key'])
    end
  end

  file '/etc/k8s-certs/cert.pem' do
    mode '0600'
  end

  file '/etc/k8s-certs/key.pem' do
    mode '0600'
  end
end