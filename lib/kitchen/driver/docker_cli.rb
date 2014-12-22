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
    class DockerCLI < Kitchen::Driver::Base

      def create(state)
        state[:image] = docker_build unless state[:image]
        state[:container_id] = docker_run(state) unless state[:container_id]
      end

      # protected

      def docker_build
        cmd = "build"
        cmd << " --no-cache" unless config[:no_cache]
        output = docker_command(cmd, :input => docker_file)
        container_id = output.chomp
        unless container_id.match(/^[0-9a-z]+$/)
          raise ActionFailed, "Build failed. Could not set CONTAINER ID."
        end
        container_id
      end

      def docker_run(state)
      end

      def docker_file
        file = ["FROM #{config[:image]}"]
        Array(config[:run_command]).each {|cmd| file << "RUN #{cmd}"}
        file.join("\n")
      end

      def docker_command(cmd, opts={})
        cmd = "docker #{cmd}"
        run_command(cmd, opts)
      end


    end
  end
end
