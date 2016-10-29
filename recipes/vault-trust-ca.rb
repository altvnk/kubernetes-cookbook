#
# Cookbook Name:: vault-issue-k8s-certs
# Recipe:: vault-trust-ca
#
# Copyright (C) 2016 Max Kozinenko
#
# All rights reserved - Do Not Redistribute
#
cert_databag = begin
                 data_bag('vault_ca')
               rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                 nil
               end

cert_databag_item = begin
                      data_bag_item('vault_ca', 'ca')
                    rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                      nil
                    end

interm_databag_item = begin
                        data_bag_item('vault_ca', 'interm')
                      rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
                        nil
                      end


if !cert_databag.nil? && !cert_databag_item.nil?
  certs = data_bag_item('vault_ca','ca')
  file '/etc/pki/ca-trust/source/anchors/internal_ca.pem' do
    content certs['ca_cert']
  end
end

if !cert_databag.nil? && !interm_databag_item.nil?
  interm = data_bag_item('vault_ca','interm')
  file '/etc/pki/ca-trust/source/anchors/k8s-infra-interm.pem' do
    content interm['interm_cert']
  end
end

execute 'update-ca-trust' do
  command 'update-ca-trust'
end
