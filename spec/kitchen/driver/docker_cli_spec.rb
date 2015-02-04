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

describe Kitchen::Driver::DockerCli, "converge" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    provisioner = double('provisioner')
    instance = double('instance')
    provisioner.stub(:create_sandbox)
    provisioner.stub(:install_command)
    provisioner.stub(:init_command)
    provisioner.stub(:prepare_command)
    provisioner.stub(:run_command)
    provisioner.stub(:cleanup_sandbox)
    instance.stub(:provisioner).and_return(provisioner)
    @docker_cli.stub(:instance).and_return(instance)
    @docker_cli.stub(:docker_transfer_command)
    @docker_cli.stub(:docker_pre_transfer_command)
    @docker_cli.stub(:execute)
    @docker_cli.stub(:run_command)
  end

  example do
    expect { @docker_cli.converge(:container_id => 'abc') }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "setup" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    busser = double('busser')
    busser.stub(:setup_cmd).and_return('setup')
    @docker_cli.stub(:busser).and_return(busser)
    @docker_cli.stub(:execute)
  end

  example do
    expect{ @docker_cli.setup(:container_id => 'abc') }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "verify" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    busser = double('busser')
    busser.stub(:sync_cmd).and_return('setup')
    busser.stub(:run_cmd).and_return('setup')
    @docker_cli.stub(:busser).and_return(busser)
    @docker_cli.stub(:execute)
  end

  example do
    expect{ @docker_cli.verify(:container_id => 'abc') }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "destroy" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
  end

  example do
    expect{ @docker_cli.destroy(:container_id => 'abc') }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "remote_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    @docker_cli.stub(:execute)
  end

  example do
    opt = {:container_id => 'abc'}
    expect{ @docker_cli.remote_command(opt, "test") }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "login_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    login_command = @docker_cli.login_command(:container_id => 'abc')
    cmd, *args = login_command.cmd_array
    cmd = "#{cmd} #{args.join(" ")}"
    expect(cmd).to eq "docker exec -t -i abc /bin/bash"
  end
end

describe Kitchen::Driver::DockerCli, "build" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    @docker_cli.stub(:docker_build_command)
    @docker_cli.stub(:docker_file)
    @docker_cli.stub(:parse_image_id)
    @docker_cli.stub(:execute)
  end

  example do
    expect{ @docker_cli.build }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "run" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new
    @docker_cli.stub(:docker_run_command)
    @docker_cli.stub(:parse_container_id)
    @docker_cli.stub(:execute)
  end

  example do
    expect{ @docker_cli.run('test') }.not_to raise_error
  end
end

describe Kitchen::Driver::DockerCli, "docker_build_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new(config)
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
  end

  context 'default' do
    let(:config)       { {:command => '/bin/bash'} }

    example do
      cmd = "run -d test /bin/bash"
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
        :link => 'mysql:db',
        :memory_limit => '256m',
        :cpu_shares => 512
      }
    end

    example do
      cmd = "run -d --name web -P -m 256m -c 512 --privileged -p 80:8080 -p 22:2222 -v /dev:/dev --link mysql:db test /bin/bash"
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
      ret << "RUN yum -y install sudo curl tar"
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end

  context 'set run_command' do
    let(:config) {
      {
        image: "ubuntu/12.04",
        platform: "ubuntu",
        run_command: ["test", "test2"]
      }
    }
    example do
      ret = "FROM ubuntu/12.04\n"
      ret = "FROM ubuntu/12.04\n"
      ret << "RUN apt-get update\n"
      ret << "RUN apt-get -y install sudo curl tar\n"
      ret << "RUN test\nRUN test2"
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
  end
end

describe Kitchen::Driver::DockerCli, "docker_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    expect(@docker_cli.docker_command('exec')).to eq "docker exec"
  end
end

describe Kitchen::Driver::DockerCli, "docker_exec_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    cmd = 'exec abc /bin/bash'
    expect(@docker_cli.docker_exec_command('abc','/bin/bash')).to eq cmd
  end
  example do
    cmd = 'exec -t -i abc /bin/bash'
    opt = {:interactive => true, :tty => true}
    expect(@docker_cli.docker_exec_command('abc', '/bin/bash', opt)).to eq cmd
  end
end

describe Kitchen::Driver::DockerCli, "docker_pre_transfer_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    provisoner = {:root_path => '/tmp/kitchen'}
    cmd = "exec abc mkdir -p /tmp/kitchen && rm -rf /tmp/kitchen/*"
    expect(@docker_cli.docker_pre_transfer_command(provisoner, 'abc')).to eq cmd
  end
end

describe Kitchen::Driver::DockerCli, "docker_transfer_command" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    provisoner = {:root_path => '/tmp/kitchen'}
    provisoner.stub(:sandbox_path).and_return('/tmp/sandbox')
    cmd = "cd /tmp/sandbox && tar cf - ./ | docker exec -i abc tar x -C /tmp/kitchen"
    expect(@docker_cli.docker_transfer_command(provisoner, 'abc')).to eq cmd
  end
end
