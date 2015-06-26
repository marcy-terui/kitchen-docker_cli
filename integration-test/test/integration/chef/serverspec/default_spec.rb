require 'spec_helper'

describe file('/tmp/integration-test') do
  it { should be_file }
  it { should contain 'OK!' }
end

describe command('hostname') do
  its(:stdout) { should match /example\.local/ }
end
