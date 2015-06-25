require 'spec_helper'

describe file('/etc/resolv.conf') do
  ['8.8.8.8', '199.85.126.10'].each do |h|
    its(:content) { should contain h }
  end
end
