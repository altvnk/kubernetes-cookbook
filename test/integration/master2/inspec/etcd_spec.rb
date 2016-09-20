describe command('/usr/bin/etcd --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/2.3.7/) }
end

describe command('/usr/bin/etcdctl --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/2.3.7/) }
end

# describe command('etcdctl member list') do
#   its(:exit_status) { should eq 0 }
#   its(:stdout) { should match(%r{name=default peerURLs=http://127.0.0.1:2380 clientURLs=http://127.0.0.1:2379,http://127.0.0.1:4001 isLeader=true}) }
# end

describe command('etcdctl set /etcd1 testvalue') do
  its(:exit_status) { should eq 0 }
end

describe command('etcdctl get /etcd1') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match('testvalue') }
end

describe command('etcdctl rm /etcd1') do
  its(:exit_status) { should eq 0 }
end

# describe command('etcdctl set /#{node['hostname']} #{node['ipaddress']}') do
#   its(:exit_status) { should eq 0 }
# end
#
# describe command('etcdctl get /#{node['hostname']}') do
#   its(:exit_status) { should eq 0 }
#   its(:stdout) { should eql(node['ipaddress']) }
# end
#
# describe command('etcdctl rm /' + node['ipaddress']) do
#   its(:exit_status) { should eq 0 }
# end
