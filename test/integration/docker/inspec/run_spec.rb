describe command('docker run hello-world') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Hello from Docker!/) }
end

describe command('docker rmi hello-world --force') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Deleted:/) }
end
