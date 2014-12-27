require 'delayed_job'
require 'delayed_webhook'
require 'test/unit'
require 'mocha/test_unit'
require 'shoulda-context'
require 'webmock/test_unit'

# Use the delayed_job test backend
require "#{Gem::Specification.find_by_name('delayed_job').gem_dir}/spec/delayed/backend/test"
Delayed::Worker.backend = Delayed::Backend::Test::Job