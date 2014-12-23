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

module Kitchen

  module Driver

    # Docker CLI driver for Kitchen.
    #
    # @author Masashi Terui <marcy9114@gmail.com>
    class DockerCli < Kitchen::Driver::Base

      default_config :command, '/bin/bash'

      default_config :image do |driver|
        driver.default_image
      end

      def default_image
        platform, version = instance.platform.name.split('-')
        if platform == 'centos' && version
          version = "centos#{version.split('.').first}"
        end
        version ? [platform, version].join(':') : platform
      end

      def create(state)
        state[:image] = build unless state[:image]
        state[:container_id] = run(state[:image]) unless state[:container_id]
      end

      def build
        output = docker_exec(docker_build_command, :input => docker_file)
        parse_image_id(output)
      end

      def run(image)
        output = docker_exec(docker_run_command(image))
        parse_container_id(output)
      end

      def docker_build_command
        cmd = 'build'
        cmd << ' --no-cache' if config[:no_cache]
        cmd << ' -'
      end

      def docker_run_command(image)
        cmd = 'run -d'
        cmd << " --name #{config[:container_name]}" if config[:container_name]
        cmd << ' -P' if config[:publish_all]
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
        file = ["FROM #{config[:image]}"]
        Array(config[:run_command]).each { |cmd| file << "RUN #{cmd}" }
        file.join("\n")
      end

      def docker_exec(cmd, opts = {})
        cmd = "docker #{cmd}"
        run_command(cmd, opts)
      end


    end
  end
end
