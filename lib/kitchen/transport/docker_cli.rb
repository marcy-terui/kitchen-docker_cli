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
      default_config :lxc_driver, false
      default_config :docker_base, "docker"
      default_config :lxc_attach_base, "sudo lxc-attach"
      default_config :lxc_console_base, "sudo lxc-console"

      def connection(state, &block)
        options = config.to_hash.merge(state)
        @connection = Kitchen::Transport::DockerCli::Connection.new(options, &block)
      end

      class Connection < Kitchen::Transport::DockerCli::Connection

        include ShellOut

        def login_command
          if @options[:lxc_driver]
            lxc_login_command
          else
            docker_login_command
          end
        end

        def docker_login_command
          args = []
          args << 'exec'
          args << '-t'
          args << '-i'
          args << @options[:container_id]
          args << '/bin/bash'
          LoginCommand.new(docker_base, args)
        end

        def lxc_login_command
          args = []
          args << 'in'
          args << "\"$(#{docker_base} inspect --format '{{.Id}}' #{@options[:container_id]})\""
          LoginCommand.new(@options[:lxc_console_base], args)
        end

        def execute(cmd)
          if cmd
            if @options[:lxc_driver]
              run_lxc(lxc_exec_command(@options[:container_id], cmd))
            else
              run_docker(docker_exec_command(@options[:container_id], cmd, :tty => true))
            end
          end
        end

        def run_lxc(cmd, options={})
          run_command("#{lxc_attach_base} #{cmd}", options)
        end

        def run_docker(cmd, options={})
          run_command("#{docker_base} #{cmd}", options)
        end

        def upload(locals, remote)
          cmd = "mkdir -p #{remote}"
          execute(cmd)
          Array(locals).each do |local|
            remote_cmd = "tar x -C #{remote}"
            if @options[:lxc_driver]
              remote_cmd = "#{lxc_attach_base} #{lxc_exec_command(@options[:container_id], remote_cmd)}"
            else
              remote_cmd = "#{docker_base} cp - #{@options[:container_id]}:#{remote}"
            end
            local_cmd  = "cd #{File.dirname(local)} && tar cf - ./#{File.basename(local)}"
            run_command("#{local_cmd} | #{remote_cmd}")
          end
        end

        def docker_exec_command(container_id, cmd, opt = {})
          exec_cmd = "exec"
          exec_cmd << " -t" if opt[:tty]
          exec_cmd << " -i" if opt[:interactive]
          exec_cmd << " #{container_id} #{wrap_command(cmd)}"
        end

        def lxc_exec_command(container_id, cmd)
          exec_cmd = " -n \"$(#{docker_base} inspect --format '{{.Id}}' #{@options[:container_id]})\""
          exec_cmd << " -- #{wrap_command(cmd)}"
        end

        def wrap_command(cmd)
          cmd.match(/\Ash\s\-c/) ? cmd : Util.wrap_command(cmd.gsub('\'', "'\\\\''"))
        end

        def docker_base
          @options[:docker_base]
        end

        def lxc_attach_base
          @options[:lxc_attach_base]
        end

      end
    end
  end
end
