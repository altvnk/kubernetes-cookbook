describe command('/usr/bin/etcd --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/2.3.7/) }
end

describe command('/usr/bin/etcdctl --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/2.3.7/) }
end

describe command('etcdctl member list') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(%r{name=default peerURLs=http://127.0.0.1:2380 clientURLs=http://127.0.0.1:2379,http://127.0.0.1:4001 isLeader=true}) }
end

describe command('etcdctl set /test a_test_value') do
  its(:exit_status) { should eq 0 }
end

describe command('etcdctl get /test') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should eql("a_test_value\n") }
end

describe command('etcdctl get /delete') do
  its(:exit_status) { should eq 4 }
  its(:stderr) { should match(/^Error:  100: Key not found/) }
end

describe command('etcdctl rm /test') do
  its(:exit_status) { should eq 0 }
end