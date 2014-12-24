# <a name="title"></a> Kitchen::DockerCli [![Build Status](https://travis-ci.org/marcy-terui/kitchen-docker_cli.svg?branch=master)](https://travis-ci.org/marcy-terui/kitchen-docker_cli) [![Coverage Status](https://coveralls.io/repos/marcy-terui/kitchen-docker_cli/badge.png)](https://coveralls.io/r/marcy-terui/kitchen-docker_cli) [![Code Climate](https://codeclimate.com/github/marcy-terui/kitchen-docker_cli/badges/gpa.svg)](https://codeclimate.com/github/marcy-terui/kitchen-docker_cli)

A Test Kitchen Driver for Docker command line interface.

## <a name="requirements"></a> Requirements

- Docker (>= 1.3)  
This driver uses ```docker exec``` command.

## <a name="installation"></a> Installation and Setup

```sh
gem install kitchen-docker_cli
```

or put ```Gemfile``` in your project directory.

```ruby
source 'https://rubygems.org'

gem 'kitchen-docker_cli'
```

and

```sh
bundle install
```

If you want to use the ```kithcen exec``` command, should you put Gemfile like this. (as of 25 Dec, 2014)

```ruby
source 'https://rubygems.org'

gem 'test-kitchen', github: 'test-kitchen/test-kitchen', ref: '237efd17dbcafd0c1334134e3f26b050f2ef49d5'
gem 'kitchen-docker_cli'
```

## <a name="config"></a> Configuration

At first, put your ```.kithcen(.local).yml``` like this.

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

The default value get from ```platform.name```.

Examples:

```yml
  image: marcy/amzn
```

### platform

The Docker image's platform.

The default value get from ```platform.name```.

Examples:

```yml
  platform: centos
```

### command

The command to be executed at ```docker run```.

The default value is ```sh -c 'while true; do sleep 1d; done;'```.

Examples:

```yml
  command: /bin/bash
```

### run_command

Adds ```RUN``` command(s) to ```Dockerfile```.

The default value is ```nil```.

Examples:

```yml
  run_command:
    - yum -y install httpd
    - service httpd start
```

### no_cache

Not use the cached image on ```docker build```.

The default value is ```true```.

Examples:

```yml
  no_cache: true
```

### container_name

Set the name of container to link other container(s).

Examples:

```yml
  container_name: web
```

### link

Set ```container_name```(and alias) of other container(s) that connect from the suite container.

Examples:

```yml
 link: mysql:db
```

Examples:

```yml
  link:
    - mysql:db
    - redis:kvs
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
