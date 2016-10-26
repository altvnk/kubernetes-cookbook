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

    init_cmd_data = {
      'id' => 'vault',
      'keys'  => [],
      'token' => ''
    }

    init_cmd.each_line do |line|
      if line.start_with?('Key ')
        key = line.split(':')[1].strip
        init_cmd_data['keys'] << key
      end

      if line.start_with?('Initial Root Token')
        token = line.split(':')[1].strip
        init_cmd_data['token'] = token
      end
    end
    databag = Chef::DataBag.new
    databag.name('vaultkeys')
    databag.create
    databag_item = Chef::DataBagItem.new
    databag_item.raw_data = init_cmd_data
    databag_item.data_bag('vaultkeys')
    databag_item.create
    databag_item.save
  end
end
