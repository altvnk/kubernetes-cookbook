#
# Cookbook Name:: kubernetes
# Recipe:: vault-unseal
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'unseal' do
  api_server "https://#{node['ipaddress']}:8200"
  unseal_keys_data_bag_name 'vault_keys'
  unseal_keys_data_bag_item_name 'vault_keys'
  action :unseal
end
