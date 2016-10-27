#
# Cookbook Name:: kubernetes
# Recipe:: vault-init
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'http://127.0.0.1:8200'

ruby_block 'vault_init' do
  block do
    Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
    init_cmd = shell_out('vault init').stdout
    # save Keys and token as DataBag items here

    init_cmd_keys = {
      'id' => 'keys',
      'keys'  => []
    }
    init_cmd_token = {
        'id' => 'vault_token',
        'token' => ''
    }

    init_cmd.each_line do |line|
      if line.start_with?('Key ')
        key = line.split(':')[1].strip
        init_cmd_keys['keys'] << key
      end

      if line.start_with?('Initial Root Token')
        token = line.split(':')[1].strip
        init_cmd_token['token'] = token
      end
    end

    if File.file?(Chef::Config[:encrypted_data_bag_secret])
      secret = Chef::EncryptedDataBagItem.load_secret(Chef::Config[:encrypted_data_bag_secret])
      data_bag_keys = Chef::EncryptedDataBagItem.encrypt_data_bag_item(init_cmd_keys, secret)
      data_bag_token = Chef::EncryptedDataBagItem.encrypt_data_bag_item(init_cmd_token, secret)
    else
      data_bag_keys = init_cmd_keys
      data_bag_token = init_cmd_token
    end


    databag = Chef::DataBag.new
    databag.name('vault_keys')
    databag.create

    databag_item = Chef::DataBagItem.new
    databag_item.raw_data = data_bag_keys
    databag_item.data_bag('vault_keys')
    databag_item.create
    databag_item.save

    databag_item = Chef::DataBagItem.new
    databag_item.raw_data = data_bag_token
    databag_item.data_bag('vault_keys')
    databag_item.create
    databag_item.save
  end
end
