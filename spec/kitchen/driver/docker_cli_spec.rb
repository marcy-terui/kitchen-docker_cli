require 'spec_helper'
require 'kitchen/driver/docker_cli'

describe Kitchen::Driver::DockerCLI do

  before do
    @docker_cli = Kitchen::Driver::DockerCLI.new(config)
    @docker_cli.stub(:docker_build).and_return("qwerty")
    @docker_cli.stub(:docker_run).and_return("asdfgf")
    @docker_cli.create(state)
  end

  context 'first kitchen create' do
    let(:config)       { Hash.new }
    let(:state)        { Hash.new }

    example { expect(state[:image]).to eq "qwerty" }
    example { expect(state[:container_id]).to eq "asdfgf" }
  end

  context 'first kitchen create' do
    let(:config)       { Hash.new }
    let(:state)        { {:image => "abc", :container_id => "xyz"} }

    example { expect(state[:image]).to eq "abc" }
    example { expect(state[:container_id]).to eq "xyz" }
  end
end
