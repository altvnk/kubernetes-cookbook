describe service('kube-apiserver') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe command('kubectl version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/GitVersion:"v1.3.6"/) }
end

describe command('kubectl cluster-info') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/running/) }
end
