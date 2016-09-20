#
# Cookbook Name:: kubernetes
# Recipe:: fixvgip
#
# Copyright (C) 2016 Tymofii Polekhin
#
# All rights reserved - Do Not Redistribute
#

interfaces = node['network']['interfaces']

if node['virtualization'] && node['virtualization']['system'] == 'vbox'
  interface_key = (interfaces.keys - ['lo', node['network']['default_interface']]).first

  unless interface_key.empty?
    interfaces[interface_key]['addresses'].each do |ip, params|
      node.automatic['ipaddress'] = ip if params['family'] == 'inet'
    end
  end
end
