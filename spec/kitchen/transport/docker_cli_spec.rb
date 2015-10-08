require 'spec_helper'
require 'kitchen/driver/docker_cli'

describe Kitchen::Driver::DockerCli, "default_image" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
  end

  example do
    platform = double('platform')
    instance = double('instance')
    platform.stub(:name).and_return("centos-6.4")
    instance.stub(:platform).and_return(platform)
    @docker_cli.stub(:instance).and_return(instance)
    expect(@docker_cli.default_image).to eq 'centos:centos6'
  end

  example do
    platform = double('platform')
    instance = double('instance')
    platform.stub(:name).and_return("ubuntu-12.04")
    instance.stub(:platform).and_return(platform)
    @docker_cli.stub(:instance).and_return(instance)
    expect(@docker_cli.default_image).to eq 'ubuntu:12.04'
  end
end
