require 'spec_helper'
require 'kitchen/driver/docker_cli'

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

  context 'default' do
    let(:config)       { Hash.new }

    example do
      expect(@docker_cli.docker_build_command).to eq 'build --no-cache -'
    end
  end

  context 'nocache' do
    let(:config)       { {:no_cache => false} }

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
      cmd = "run -d -v #{Dir::tmpdir}:/tmp:rw test /bin/bash"
      expect(@docker_cli.docker_run_command('test')).to eq cmd
    end
  end

  context 'set configs' do
    let(:config) do
      {
        :command => '/bin/bash',
        :container_name => 'web',
        :publish_all => true,
        :publish => ['80:8080', '22:2222'],
        :volume => '/dev:/dev',
        :link => 'mysql:db'
      }
    end

    example do
      cmd = "run -d -v #{Dir::tmpdir}:/tmp:rw --name web -P -p 80:8080 -p 22:2222 -v /dev:/dev --link mysql:db test /bin/bash"
      expect(@docker_cli.docker_run_command('test')).to eq cmd
    end
  end
end

describe Kitchen::Driver::DockerCli, "parse_image_id" do

  before do
    @docker_cli = Kitchen::Driver::DockerCli.new()
  end

  example do
    expect do
      output = "Successfully built abc123def456\n"
      @docker_cli.parse_image_id(output).to eq "abc123def456"
    end
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
      ret << "RUN yum -y install sudo curl"
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
      ret << "RUN apt-get -y install sudo curl\n"
      ret << "RUN test\nRUN test2"
      expect(@docker_cli.send(:docker_file)).to eq ret
    end
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
