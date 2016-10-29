#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: vault-issue-k8s-certs
#
# Copyright (C) 2016 Oleksii Slobodyskyi
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['vault']['pki'][rand(2)] + ':8200'

if !File.file?('/etc/k8s-certs/key.pem')
  directory '/etc/k8s-certs' do
    mode '0700'
    action :create
  end
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

    ruby_block 'create_kubernetes_certs' do
      block do

        stdout = shell_out("vault write -format=json k8s-infra-interm/issue/server common_name=\"#{node['fqdn']}\" ip_sans=\"#{node['ipaddress']}\" ttl=8760h format=pem").stdout
        parsed_stdout = JSON.parse(stdout)

        File.write('/etc/k8s-certs/cert.pem', parsed_stdout['data']['certificate'])
        open('/etc/k8s-certs/cert.pem', 'a') do |f|
          f.puts '\n'
          f.puts parsed_stdout['data']['issuing_ca']
        end
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
end
