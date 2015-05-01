require "kitchen"

module Kitchen
  module Transport
    class DockerCli < Kitchen::Transport::Base
      class Connection < Kitchen::Transport::Base::Connection ; end
    end
  end
end
