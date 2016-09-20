describe service('docker') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe command('docker run hello-world') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Hello from Docker!/) }
end

describe command('docker rmi hello-world --force') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Deleted:/) }
end

describe command('docker info') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Storage Driver: overlay/) }
  its(:stdout) { should match(/Server Version: 1.12.1/) }
end
