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
  s.add_dependency 'bogo'
  s.add_dependency 'bogo-config'
  s.add_dependency 'bogo-ui'
  s.add_dependency 'slop', '~> 3'
  s.files = Dir['lib/**/*'] + %w(bogo-cli.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
