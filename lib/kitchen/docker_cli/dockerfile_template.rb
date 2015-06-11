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

require 'erb'

module Kitchen

  module DockerCli

    class DockerfileTemplate
      def initialize(vars={}, config={})
        vars.each do |k, v|
          instance_variable_set("@#{k.to_s}", v)
        end
        self.class.class_eval <<-EOF
          def config
            return #{config.to_s}
          end
        EOF
      end

      def result
        ERB.new(IO.read(File.expand_path(config[:dockerfile]))).result(binding)
      end
    end
  end
end
