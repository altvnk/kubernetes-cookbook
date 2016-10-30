#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: renew-vault-certs
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'

unless File.file?('/etc/k8s-certs/cert.pem')
  directory '/etc/k8s-certs' do
    mode '0755'
    action :create
  end

  token_databag_item = begin
                         data_bag_item('vault_keys', 'vault_token')
                       rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                         nil
                       end
  unless token_databag_item.nil?
    token = data_bag_item('vault_keys', 'vault_token')['token']
    execute 'vault_auth' do
      command "vault auth #{token}"
    end

    ruby_block 'create_vault_certs' do
      block do
        stdout = shell_out("vault write -format=json k8s-infra-interm/issue/server common_name=\"#{node['fqdn']}\" ip_sans=\"#{node['ipaddress']}\" ttl=8760h format=pem").stdout
        parsed_stdout = JSON.parse(stdout)
        certfile = parsed_stdout['data']['certificate'] + '\n'
        parsed_stdout['data']['ca_chain'].each do |chain|
          certfile += chain + '\n'
        end
        certfile += parsed_stdout['data']['issuing_ca']
        File.write('/etc/k8s-certs/cert.pem', certfile)
        File.write('/etc/k8s-certs/key.pem', parsed_stdout['data']['private_key'])
      end
    end

    file '/etc/k8s-certs/cert.pem' do
      mode '0755'
    end

    file '/etc/k8s-certs/key.pem' do
      mode '0755'
    end
  end
end

if File.file?('/etc/k8s-certs/key.pem') && File.file?('/etc/k8s-certs/cert.pem')

  file '/etc/vault/cert.pem' do
    not_if { ::FileUtils.compare_file('/etc/vault/cert.pem', '/etc/k8s-certs/cert.pem') }
    mode 0755
    content ::File.open('/etc/k8s-certs/cert.pem').read
    action :create
  end

  file '/etc/vault/key.pem' do
    not_if { ::FileUtils.compare_file('/etc/vault/key.pem', '/etc/k8s-certs/key.pem') }
    mode 0755
    content ::File.open('/etc/k8s-certs/key.pem').read
    action :create
    notifies :restart, 'service[vault]', :immediately
  end

  service 'vault' do
    action [:enable, :start]
  end

  include_recipe 'kubernetes::vault-unseal'

end
