# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/driver/docker_cli_version'

Gem::Specification.new do |spec|
  spec.name          = 'kitchen-docker_cli'
  spec.version       = Kitchen::Driver::DOCKER_CLI_VERSION
  spec.authors       = ['Masashi Terui']
  spec.email         = ['marcy9114@gmail.com']
  spec.description   = %q{A Test Kitchen Driver for Docker native CLI}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/marcy-terui/kitchen-docker_cli'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'test-kitchen', '>= 1.3'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
end
