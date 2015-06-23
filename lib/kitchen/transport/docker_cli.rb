# -*- encoding: utf-8 -*-
#
# Author:: Masashi Terui (<marcy9114@gmail.com>)
#
# Copyright (C) 2015, Masashi Terui
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

require "kitchen"
require 'thor/util'

module Kitchen
  module Transport
    class DockerCli < Kitchen::Transport::Base

      class DockerCliFailed < TransportFailed; end

      kitchen_transport_api_version 1
      plugin_version Kitchen::VERSION

      default_config :host, nil

      def connection(state, &block)
        options = config.to_hash.merge(state)
        @connection = Kitchen::Transport::DockerCli::Connection.new(options, &block)
      end

      class Connection < Kitchen::Transport::DockerCli::Connection

        include ShellOut

        def login_command
          args = []
          args << 'exec'
          args << '-t'
          args << '-i'
          args << @options[:container_id]
          args << '/bin/bash'
          LoginCommand.new(binary, args)
        end

        def execute(command)
          if command
            exec_cmd = docker_exec_command(@options[:container_id], command, :tty => true)
            run_docker(exec_cmd)
          end
        end

        def run_docker(command, options={})
          run_command("#{binary} #{command}", options)
        end

        def upload(locals, remote)
          cmd = "mkdir -p #{remote}"
          execute(cmd)
          Array(locals).each do |local|
            remote_cmd = "tar x -C #{remote}"
            remote_cmd = "#{binary} #{docker_exec_command(@options[:container_id], remote_cmd, :interactive => true)}"
            local_cmd  = "cd #{File.dirname(local)} && tar cf - ./#{File.basename(local)}"
            run_command("#{local_cmd} | #{remote_cmd}")
          end
        end

        def docker_exec_command(container_id, cmd, opt = {})
          exec_cmd = "exec"
          exec_cmd << " -t" if opt[:tty]
          exec_cmd << " -i" if opt[:interactive]
          cmd = Util.wrap_command(cmd.gsub('\'', '"')) unless cmd.match(/\Ash\s\-c/)
          exec_cmd << " #{container_id} #{cmd}"
        end

        def binary
          "docker"
        end

      end
    end
  end
end
