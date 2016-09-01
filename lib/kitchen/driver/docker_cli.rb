# -*- encoding: utf-8 -*-
#
# Author:: Masashi Terui (<marcy9114@gmail.com>)
#
# Copyright (C) 2014, Masashi Terui
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen'
require 'kitchen/docker_cli/dockerfile_template'

module Kitchen

  module Driver

    # Docker CLI driver for Kitchen.
    #
    # @author Masashi Terui <marcy9114@gmail.com>
    class DockerCli < Kitchen::Driver::Base

      default_config :no_cache, false
      default_config :build_context, false
      default_config :command, 'sh -c \'while true; do sleep 1d; done;\''
      default_config :privileged, false
      default_config :instance_host_name, false
      default_config :instance_container_name, false
      default_config :transport, "docker_cli"
      default_config :dockerfile_vars, {}
      default_config :skip_preparation, false
      default_config :destroy_container_name, true

      default_config :image do |driver|
        driver.default_image
      end

      default_config :platform do |driver|
        driver.default_platform
      end

      def default_image
        platform, version = instance.platform.name.split('-')
        if platform == 'centos' && version
          version = "centos#{version.split('.').first}"
        end
        version ? [platform, version].join(':') : platform
      end

      def default_platform
        instance.platform.name.split('-').first
      end

      def create(state)
        state[:image] = build(state) unless state[:image]
        state[:container_id] = run(state) unless state[:container_id]
      end

      def destroy(state)
        instance.transport.connection(state) do |conn|
          begin
            if state[:container_id]
              output = conn.run_docker("ps -a -q -f id=#{state[:container_id]}").chomp
              conn.run_docker("rm -f #{state[:container_id]}") unless output.empty?
            end
            if config[:destroy_container_name] && container_name
              output = conn.run_docker("ps -a -q -f name=#{container_name}").chomp
              conn.run_docker("rm -f #{container_name}") unless output.empty?
            end
            FileUtils.rm_f(dockerfile_path)
          rescue => e
            raise e unless conn.send(:options)[:lxc_driver]
          end
        end
      end

      def build(state)
        output = ""
        instance.transport.connection(state) do |conn|
          if config[:build_context]
            # Dockerfile is sent using `-f` option
            output = conn.run_docker(docker_build_command)
          else
            # Dockerfile contents is sent using stdin
            output = conn.run_docker(docker_build_command, :input => docker_file)
          end
        end
        parse_image_id(output)
      end

      def run(state)
        output = ""
        instance.transport.connection(state) do |conn|
          output = conn.run_docker(docker_run_command(state[:image]))
        end
        parse_container_id(output)
      end

      def dockerfile_path
        "#{config[:kitchen_root]}/.kitchen/#{config[:dockerfile]}_#{instance.name}_rendered"
      end

      def docker_build_command
        cmd = String.new('build')
        cmd << ' --no-cache' if config[:no_cache]
        if config[:build_context]
          dockerfile_contents = docker_file()
          # save the Dockerfile contents rendered with ERB variables
          File.write(dockerfile_path, dockerfile_contents)
          cmd << " -f #{dockerfile_path}"
          cmd << ' .'
        else
          cmd << ' -'
        end
      end

      def docker_run_command(image)
        cmd = String.new("run -d -t")
        cmd << " --name #{container_name}" if container_name
        cmd << ' -P' if config[:publish_all]
        cmd << " -m #{config[:memory_limit]}" if config[:memory_limit]
        cmd << " -c #{config[:cpu_shares]}" if config[:cpu_shares]
        cmd << " --security-opt #{config[:security_opt]}" if config[:security_opt]
        cmd << ' --privileged' if config[:privileged]
        cmd << " --net #{config[:network]}" if config[:network]
        if config[:hostname]
          cmd << " -h #{config[:hostname]}"
        elsif config[:instance_host_name]
          cmd << " -h #{instance.name}"
        end
        Array(config[:publish]).each { |pub| cmd << " -p #{pub}" }
        Array(config[:volume]).each { |vol| cmd << " -v #{vol}" }
        Array(config[:volumes_from]).each { |vf| cmd << " --volumes-from #{vf}" }
        Array(config[:link]).each { |link| cmd << " --link #{link}" }
        Array(config[:expose]).each { |exp| cmd << " --expose #{exp}" }
        Array(config[:dns]).each {|dns| cmd << " --dns #{dns}"}
        Array(config[:add_host]).each {|mapping| cmd << " --add-host #{mapping}"}
        cmd << " #{image} #{config[:command]}"
      end

      def container_name
        if config[:container_name]
          config[:container_name]
        elsif config[:instance_container_name]
          instance.name
        end
      end

      def parse_image_id(output)
        unless output.chomp.match(/Successfully built ([0-9a-z]{12})$/)
          raise ActionFailed, 'Could not parse IMAGE ID.'
        end
        $1
      end

      def parse_container_id(output)
        unless output.chomp.match(/([0-9a-z]{64})$/)
          raise ActionFailed, 'Could not parse CONTAINER ID.'
        end
        $1
      end

      def docker_file
        if config[:dockerfile]
          file = ::Kitchen::DockerCli::DockerfileTemplate.new(
            config[:dockerfile_vars],
            config.to_hash
          ).result
        else
          file = ["FROM #{config[:image]}"]
          unless config[:skip_preparation]
            case config[:platform]
            when 'debian', 'ubuntu'
              file << 'RUN apt-get update'
              file << 'RUN apt-get -y install sudo curl tar'
            when 'rhel', 'centos', 'fedora'
              file << 'RUN yum clean all'
              file << 'RUN yum -y install sudo curl tar'
              file << 'RUN echo "Defaults:root !requiretty" >> /etc/sudoers'
            else
              # TODO: Support other distribution
            end
          end
          Array(config[:environment]).each { |env, value| file << "ENV #{env}=#{value}" }
          Array(config[:run_command]).each { |cmd| file << "RUN #{cmd}" }
          file.join("\n")
        end
      end


    end
  end
end
