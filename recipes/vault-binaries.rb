#
# Cookbook Name:: kubernetes
# Recipe:: vault-binaries
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#

remote_file 'vault package' do
  path "#{Chef::Config[:file_cache_path]}/vault_package.zip"
  source 'https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip'
end

zipfile "#{Chef::Config[:file_cache_path]}/vault_package.zip" do
  not_if { ::File.exist?('/usr/local/bin/vault') }
  into '/usr/local/bin'
end
