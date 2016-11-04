#
# Cookbook Name:: kubernetes
# Recipe:: vault-binaries
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

vault 'install_binaries' do
  package_url 'https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip'
  action :install_binaries
end
