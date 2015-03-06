# <a name="title"></a> Kitchen::DockerCli [![Gem Version](https://badge.fury.io/rb/kitchen-docker_cli.svg)](http://badge.fury.io/rb/kitchen-docker_cli) [![Build Status](https://travis-ci.org/marcy-terui/kitchen-docker_cli.svg?branch=master)](https://travis-ci.org/marcy-terui/kitchen-docker_cli) [![Coverage Status](https://coveralls.io/repos/marcy-terui/kitchen-docker_cli/badge.png)](https://coveralls.io/r/marcy-terui/kitchen-docker_cli)

[![Join the chat at https://gitter.im/marcy-terui/kitchen-docker_cli](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/marcy-terui/kitchen-docker_cli?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
A Test Kitchen Driver for Docker command line interface.

This plugin is created with only Docker CLI functions.
Therefore, we can test with an environment that has no extra software such as ```sshd```.

## <a name="requirements"></a> Requirements

- Test-Kitchen (>= 1.3)

- Docker (>= 1.3)
This driver uses `docker exec` command.

- tar (GNU Tar)

## <a name="installation"></a> Installation and Setup

```sh
gem install kitchen-docker_cli
```

or put `Gemfile` in your project directory.

```ruby
source 'https://rubygems.org'

gem 'kitchen-docker_cli'
```

and

```sh
bundle install
```

## <a name="config"></a> Configuration

At first, put your `.kithcen(.local).yml` like this.

```yml
---
driver:
  name: docker_cli

platforms:
  - name: ubuntu-12.04
  - name: centos-6.4

suites:
  - name: default
    run_list:
    attributes:
```

### image

The Docker image's path.

The default value get from `platform.name`.

Examples:

```yml
  image: marcy/amzn
```

### platform

The Docker image's platform.

The default value get from `platform.name`.

Examples:

```yml
  platform: centos
```

### command

The command to be executed at `docker run`.

The default value is `sh -c 'while true; do sleep 1d; done;'`.

Examples:

```yml
  command: /bin/bash
```

### run_command

Adds `RUN` command(s) to `Dockerfile`.

The default value is `nil`.

Examples:

```yml
  run_command:
    - yum -y install httpd
    - service httpd start
```

### environment

Adds `ENV` command(s) to `Dockerfile`.

The default value is `nil`.

Examples:

```yml
environment:
  http_proxy: http://proxy.example.com:8080/
  LANG: ja_JP.UTF-8
```

### no_cache

Not use the cached image on `docker build`.

The default value is `false`.

Examples:

```yml
  no_cache: true
```

### privileged

Give extended privileges to the suite container.

The default value is `false`.

Examples:

```yml
  privileged: true
```

### container_name

Set the name of container to link other container(s).

Examples:

```yml
  container_name: web
```

### network

Set the Network mode for the container.  
- `bridge`: creates a new network stack for the container on the docker bridge
- `none`: no networking for this container
- `container:<name|id>`: reuses another container network stack
- `host`: use the host network stack inside the container

Examples:

```yml
  network: host
```

### hostname

Set hostname to container.

Examples:

```yml
  hostname: example.local
```

### instance_host_name
Use instance name to hostname.

The default value is `false`.

Examples:

```yml
  instance_host_name: true
```

### link

Set `container_name`(and alias) of other container(s) that connect from the suite container.

Examples:

```yml
 link: mysql:db
```

```yml
  link:
    - mysql:db
    - redis:kvs
```

### publish

Publish a container's port or a range of ports to the host.

The default value is `nil`.

Examples:

```yml
  publish: 80
```

```yml
  publish:
    - 80:8080
    - 22:2222
```

### publish_all

Publish all exposed ports to the host interfaces.
This option used to communicate between some containers.

The default value is `false`.

Examples:

```yml
  publish_all: true
```

### volume

Adds data volume(s) to the container.

Examples:

```yml
  volume: /data
```

```yml
  volume:
    - /tmp:/tmp
    - <%= Dir::pwd %>:/var:rw
```

### dockerfile

Create test image using a supplied dockerfile, instead of the default dockerfile created.  
For best results, please:  
  - Ensure Package Repositories are updated
  - Ensure Dockerfile installs sudo, curl, and tar
  - If Ubuntu/Debian, Set DEBIAN_FRONTEND to noninteractive

```yml
  dockerfile: my/dockerfile
```

### memory_limit

Constrain the memory available.

```yml
  memory_limit: 256m
```

### cpu_shares

Change the priority of CPU Time.  
This option with value 0 indicates that the running container has access to all 1024 (default) CPU shares.

```yml
  cpu_shares: 512
```

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="authors"></a> Authors

Created and maintained by [Masashi Terui][author] (<marcy9114@gmail.com>)

## <a name="license"></a> License

Apache 2.0 (see [LICENSE][license])


[author]:           https://github.com/marcy-terui
[issues]:           https://github.com/marcy-terui/kitchen-docker_cli/issues
[license]:          https://github.com/marcy-terui/kitchen-docker_cli/blob/master/LICENSE
[repo]:             https://github.com/marcy-terui/kitchen-docker_cli
[driver_usage]:     http://docs.kitchen-ci.org/drivers/usage
[chef_omnibus_dl]:  http://www.getchef.com/chef/install/
