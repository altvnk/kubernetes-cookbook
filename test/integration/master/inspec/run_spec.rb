describe command('kubectl cluster-info') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Kubernetes master is running/) }
end

describe command('kubectl api-versions') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/v1/) }
end

describe command('kubectl version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Server Version: version.Info/) }
end
