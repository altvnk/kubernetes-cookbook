#
# Cookbook Name:: kubernetes
# Recipe:: vault-init
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'init' do
  api_server "https://#{node['ipaddress']}:8200"
  unseal_keys_data_bag_name 'vault_keys'
  unseal_keys_data_bag_item_name 'vault_keys'
  initial_token_data_bag_name 'vault_keys'
  initial_token_data_bag_item_name 'vault_token'
  action :init
end
