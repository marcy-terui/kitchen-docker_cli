require 'spec_helper'
require 'kitchen/driver/docker_cli'

describe Kitchen::Driver::DockerCLI, "create" do

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

  context 'second kitchen create' do
    let(:config)       { Hash.new }
    let(:state)        { {:image => "abc", :container_id => "xyz"} }

    example { expect(state[:image]).to eq "abc" }
    example { expect(state[:container_id]).to eq "xyz" }
  end
end

describe Kitchen::Driver::DockerCLI, "docker_build" do

  before do
    @docker_cli = Kitchen::Driver::DockerCLI.new(config)
  end

  context 'success' do
    before do
      @docker_cli.stub(:docker_command).and_return("abc123def456\n")
    end
    let(:config) { Hash.new }
    example { expect(@docker_cli.send(:docker_build)).to eq "abc123def456" }
  end

  # context 'fail' do
  #   before do
  #     @docker_cli.stub(:docker_command).and_return("Error Error!\n")
  #   end
  #   let(:config) { Hash.new }
  #   example { expect(@docker_cli.send(:docker_build)).to raise_error }
  # end
end

describe Kitchen::Driver::DockerCLI, "docker_file" do

  before do
    @docker_cli = Kitchen::Driver::DockerCLI.new(config)
  end

  context 'not set run_command' do
    let(:config) { {image: "centos/centos6"} }
    example { expect(@docker_cli.send(:docker_file)).to eq "FROM centos/centos6" }
  end

  context 'set run_command' do
    let(:config) {
      {
        image: "centos/centos6",
        run_command: ["test", "test2"]
      }
    }
    example { expect(@docker_cli.send(:docker_file)).to eq "FROM centos/centos6\nRUN test\nRUN test2" }
  end
end
