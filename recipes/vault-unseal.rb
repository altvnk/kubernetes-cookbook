#
# Cookbook Name:: kubernetes
# Recipe:: vault-unseal
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'


ruby_block 'vault_unseal' do
  block do
    Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
    # unseal cmd
 #   if File.file?(Chef::Config[:encrypted_data_bag_secret])
 #     secret = Chef::EncryptedDataBagItem.load_secret(Chef::Config[:encrypted_data_bag_secret])
 #     keys = data_bag_item('vault_keys', 'keys', secret)
 #   else
    key = []
    for i in 1..5 do
      key_id = 'key' + i.to_s
      key_databag_item = begin
                           data_bag_item('vault_keys', key_id)
                         rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                           nil
                         end
      if !key_databag_item.nil?
        key[i] = data_bag_item('vault_keys', key_id)['key']
        command = 'vault unseal ' + key[i]
        shell_out(command)
      end
    end
 #   end
  end
end
