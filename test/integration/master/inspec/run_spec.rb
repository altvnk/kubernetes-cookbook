describe command('kubectl cluster-info') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/\e[0;32mKubernetes master\e[0m is running at/) }
end

describe command('kubectl api-versions') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/v1/) }
end

describe command('kubectl version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Server Version: version.Info/) }
end
