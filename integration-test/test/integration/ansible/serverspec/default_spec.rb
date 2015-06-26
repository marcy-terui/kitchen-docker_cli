require 'spec_helper'

describe package('git') do
  it { should be_installed }
end

describe command('hostname') do
  its(:stdout) { should match /example\.local/ }
end
