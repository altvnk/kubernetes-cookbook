#
# Cookbook Name:: kubernetes
# Recipe:: vault-init
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'https://' + node['ipaddress'] + ':8200'

ruby_block 'vault_init' do
  block do
    Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
    init_cmd = shell_out('vault init').stdout
    # save Keys and token as DataBag items here

    init_cmd_keys = {
      'id' => '',
      'key'  => ''
    }
    init_cmd_token = {
        'id' => 'vault_token',
        'token' => ''
    }

    init_cmd.each_line.with_index do |line, index|
      if line.start_with?('Unseal Key ')
        value = line.split(':')[1].strip
        init_cmd_keys['id'] = 'key' + (index+1).to_s
        init_cmd_keys['key'] = value
        if !value.empty?

          databag = begin
                      data_bag('vault_keys')
                    rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                      nil
                    end

          databag_item = begin
                           data_bag_item('vault_keys', init_cmd_keys['id'])
                         rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                           nil
                         end

          if databag && databag_item
            write_to = data_bag_item('vault_keys', init_cmd_keys['id'])
            write_to['key'] = init_cmd_keys['key']
            write_to.save
          else if !databag
            databag = Chef::DataBag.new
            databag.name('vault_keys')
            databag.create
          else if !databag_item
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('vault_keys')
            databag_item.raw_data = init_cmd_keys
            databag_item.create
            databag_item.save
          end
          end
          end
        end
      end

      if line.start_with?('Initial Root Token')
        token = line.split(':')[1].strip
        init_cmd_token['token'] = token
        if !token.empty?

          databag = begin
                      data_bag('vault_keys')
                    rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                      nil
                    end

          databag_item = begin
                           data_bag_item('vault_keys', 'vault_token')
                         rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                           nil
                         end

          if databag && databag_item
            write_to = data_bag_item('vault_keys', 'vault_token')
            write_to['token'] = init_cmd_token['token']
            write_to.save
          else if !databag
            databag = Chef::DataBag.new
            databag.name('vault_keys')
            databag.create
          else if !databag_item
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('vault_keys')
            databag_item.raw_data = init_cmd_token
            databag_item.create
            databag_item.save
          end
          end
          end
        end
      end
    end

 #   if File.file?(Chef::Config[:encrypted_data_bag_secret])
 #     secret = Chef::EncryptedDataBagItem.load_secret(Chef::Config[:encrypted_data_bag_secret])
 #     data_bag_keys = Chef::EncryptedDataBagItem.encrypt_data_bag_item(init_cmd_keys, secret)
 #     data_bag_token = Chef::EncryptedDataBagItem.encrypt_data_bag_item(init_cmd_token, secret)
 #   else
 #     data_bag_keys = init_cmd_keys
 #     data_bag_token = init_cmd_token
 #   end


 #   databag = Chef::DataBag.new
 #   databag.name('vault_keys')
 #   databag.create

 #   databag_item = Chef::DataBagItem.new
 #   databag_item.raw_data = data_bag_keys
 #   databag_item.data_bag('vault_keys')
#    databag_item.create
#    databag_item.save


#    databag_item.create

  end
end
