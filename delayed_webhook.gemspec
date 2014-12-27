# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed_webhook/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_webhook'
  spec.version       = DelayedWebhook::VERSION
  spec.authors       = ['Kevin Montag']
  spec.email         = ['team@angel.co']
  spec.summary       = 'Robust webhook execution using delayed_job and httparty.'
  spec.homepage      = 'https://github.com/venturehacks/delayed_webhook'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.0'

  spec.add_runtime_dependency 'delayed_job', '~> 3.0'
  spec.add_runtime_dependency 'httparty', '~> 0.13'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'shoulda-context', '~> 1.2'
  spec.add_development_dependency 'test-unit', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 1.20'

end
