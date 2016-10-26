#
# Cookbook Name:: kubernetes
# Recipe:: vault-unseal
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'http://127.0.0.1:8200'

ruby_block 'vault_unseal' do
  block do
    Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
    # unseal cmd
  end
end
