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

describe Kitchen::Driver::DockerCli, "default_platform" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
  end

  example do
    platform = double('platform')
    instance = double('instance')
    platform.stub(:name).and_return("centos-6.4")
    instance.stub(:platform).and_return(platform)
    @docker_cli.stub(:instance).and_return(instance)
    expect(@docker_cli.default_platform).to eq 'centos'
  end
end

describe Kitchen::Driver::DockerCli, "create" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new(config)
    @docker_cli.stub(:build).and_return("qwerty")
    @docker_cli.stub(:run).and_return("asdfgf")
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

describe Kitchen::Driver::DockerCli, "docker_build_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new(config)
  end

  context 'build_context' do
    let(:config)	{ {:build_context => true} }
    
    example do
      expect(@docker_cli.docker_build_command).to eq 'build .'
    end
  end

  context 'build_pull specified' do
    let(:config)	{ {:build_pull => false} }

    example do
      expect(@docker_cli.docker_build_command).to include '--pull=false'
    end
  end

  context 'default' do
    let(:config)       { {:no_cache => true} }

    example do
      expect(@docker_cli.docker_build_command).to eq 'build --no-cache -'
    end
  end

  context 'nocache' do
    let(:config)       { Hash.new }

    example do
      expect(@docker_cli.docker_build_command).to eq 'build -'
    end
  end

end

describe Kitchen::Driver::DockerCli, "docker_run_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new(config)
    instance = double('instance')
    instance.stub(:name).and_return("default-centos-66")
    @docker_cli.stub(:instance).and_return(instance)
  end

  context 'default' do
    let(:config)       { {:command => '/bin/bash'} }

    example do
      cmd = "run -d -t test /bin/bash"
      expect(@docker_cli.docker_run_command('test')).to eq cmd
    end
  end

  context 'set configs' do
    let(:config) do
      {
        :command => '/bin/bash',
        :container_name => 'web',
        :publish_all => true,
        :privileged => true,
        :publish => ['80:8080', '22:2222'],
        :volume => '/dev:/dev',
        :volumes_from => 'data',
        :link => 'mysql:db',
        :expose => 80,
        :memory_limit => '256m',
        :cpu_shares => 512,
        :network => 'none',
        :hostname => 'example.local',
        :instance_host_name => true,
        :dns => ['8.8.8.8', '8.8.4.4'],
        :add_host => ['myhost:127.0.0.1']
      }
    end

    example do
      cmd = "run -d -t --name web -P -m 256m -c 512 --privileged --net none -h example.local -p 80:8080 -p 22:2222 -v /dev:/dev --volumes-from data --link mysql:db --expose 80 --dns 8.8.8.8 --dns 8.8.4.4 --add-host myhost:127.0.0.1 test /bin/bash"
      expect(@docker_cli.docker_run_command('test')).to eq cmd
    end
  end
end

describe Kitchen::Driver::DockerCli, "parse_image_id" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    expect { @docker_cli.parse_image_id("Successfully built abc123def456\n").to eq "abc123def456" }
  end
  example do
    expect { @docker_cli.parse_image_id("Successfully built abc123\n") }.to raise_error('Could not parse IMAGE ID.')
  end
  example do
    expect { @docker_cli.parse_image_id("Error abc123def456\n") }.to raise_error('Could not parse IMAGE ID.')
  end

end

describe Kitchen::Driver::DockerCli, "parse_container_id" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    expect do
      output = "abcd1234efgh5678"
      output << "abcd1234efgh5678"
      output << "abcd1234efgh5678"
      output << "abcd1234efgh5678\n"
      @docker_cli.parse_container_id(output).to eq output.chomp
    end
  end

  example do
    expect do
      output = "abcd1234efgh5678"
      output << "abcd1234efgh5678"
      output << "abcd1234efgh5678\n"
      @docker_cli.parse_container_id(output)
    end.to raise_error('Could not parse CONTAINER ID.')
  end

end

describe Kitchen::Driver::DockerCli, "docker_file" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new(config)
  end

  context 'not set run_command' do
    let(:config) do
      {
        image: "centos/centos6",
        platform: "centos"
      }
    end
    example do
      ret = "FROM centos/centos6\n"
      ret << "RUN yum clean all\n"
      ret << "RUN yum -y install sudo curl tar\n"
      ret << 'RUN echo "Defaults:root !requiretty" >> /etc/sudoers'
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end

  context 'set run_command' do
    let(:config) {
      {
        image: "ubuntu/12.04",
        platform: "ubuntu",
        run_command: ["test", "test2"],
        environment: {"test" => "hoge"}
      }
    }
    example do
      ret = "FROM ubuntu/12.04\n"
      ret << "RUN apt-get update\n"
      ret << "RUN apt-get -y install sudo curl tar\n"
      ret << "ENV test=hoge\n"
      ret << "RUN test\n"
      ret << "RUN test2"
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end
  context 'dockerfile template' do
    let(:config) {
      {
        image: "ubuntu/12.04",
        platform: "ubuntu",
        dockerfile: File.join(File.dirname(__FILE__), 'dockerfile.erb'),
        dockerfile_vars: {"LANG" => "ja_JP.UTF-8"}
      }
    }
    example do
      ret = <<-EOH
FROM ubuntu/12.04
ENV LANG ja_JP.UTF-8
EOH
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end
  context 'dockerfile template when dockerfile_vars is nil' do
    let(:config) {
      {
        image: "ubuntu/12.04",
        platform: "ubuntu",
        dockerfile: File.join(File.dirname(__FILE__), 'dockerfile_nil.erb'),
        dockerfile_vars: nil
      }
    }
    example do
      ret = <<-EOH
FROM ubuntu/12.04
EOH
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end
end
