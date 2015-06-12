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
      default_config :command, 'sh -c \'while true; do sleep 1d; done;\''
      default_config :privileged, false
      default_config :instance_host_name, false
      default_config :transport, "docker_cli"
      default_config :dockerfile_vars, {}

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
          conn.run_docker("rm -f #{state[:container_id]}") rescue false
        end
      end

      def build(state)
        output = ""
        instance.transport.connection(state) do |conn|
          output = conn.run_docker(docker_build_command, :input => docker_file)
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

      def docker_build_command
        cmd = 'build'
        cmd << ' --no-cache' if config[:no_cache]
        cmd << ' -'
      end

      def docker_run_command(image)
        cmd = "run -d -t"
        cmd << " --name #{config[:container_name]}" if config[:container_name]
        cmd << ' -P' if config[:publish_all]
        cmd << " -m #{config[:memory_limit]}" if config[:memory_limit]
        cmd << " -c #{config[:cpu_shares]}" if config[:cpu_shares]
        cmd << ' --privileged' if config[:privileged]
        cmd << " --net #{config[:network]}" if config[:network]
        if config[:hostname]
          cmd << " -h #{config[:hostname]}"
        elsif config[:instance_host_name]
          cmd << " -h #{instance.name}"
        end
        Array(config[:publish]).each { |pub| cmd << " -p #{pub}" }
        Array(config[:volume]).each { |vol| cmd << " -v #{vol}" }
        Array(config[:link]).each { |link| cmd << " --link #{link}" }
        cmd << " #{image} #{config[:command]}"
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
          case config[:platform]
          when 'debian', 'ubuntu'
            file << 'RUN apt-get update'
            file << 'RUN apt-get -y install sudo curl tar'
          when 'rhel', 'centos', 'fedora'
            file << 'RUN yum clean all'
            file << 'RUN yum -y install sudo curl tar'
          else
            # TODO: Support other distribution
          end
          Array(config[:environment]).each { |env, value| file << "ENV #{env}=#{value}" }
          Array(config[:run_command]).each { |cmd| file << "RUN #{cmd}" }
          file.join("\n")
        end
      end


    end
  end
end
