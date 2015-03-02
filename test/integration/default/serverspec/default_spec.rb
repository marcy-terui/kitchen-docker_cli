require 'serverspec'
set :backend, :exec

set :path, '/sbin:/usr/local/sbin:$PATH'

describe file('/tmp') do
  it { should be_directory }
end

describe command('hostname') do
  its(:stdout) { should match /example\.local/ }
end
