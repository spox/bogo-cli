$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'bogo-cli/version'
Gem::Specification.new do |s|
  s.name = 'bogo-cli'
  s.version = Bogo::Cli::VERSION.version
  s.summary = 'CLI Helper libraries'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/spox/bogo-cli'
  s.description = 'CLI Helper libraries'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'bogo', '>= 0.1.6', '< 0.6'
  s.add_runtime_dependency 'bogo-config', '>= 0.1.15', '< 0.5'
  s.add_runtime_dependency 'bogo-ui'
  s.add_runtime_dependency 'slop', '~> 3'
  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'minitest'
  s.files = Dir['lib/**/*'] + %w(bogo-cli.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
