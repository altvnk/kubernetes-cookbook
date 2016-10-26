#
# Cookbook Name:: kubernetes
# Recipe:: vault-init
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

ENV['VAULT_ADDR'] = 'http://127.0.0.1:8200'

ruby_block "vault_init" do
  block do
    Chef::Resource::RubyBlock.send(:include,Chef::Mixin::ShellOut)
    init_cmd = shell_out("vault init")
  end
end

file '/etc/vault/vault.secrets' do
  content init_cmd
end
