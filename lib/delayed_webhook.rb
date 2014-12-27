require 'delayed_webhook/configuration'
require 'delayed_webhook/job'
require 'delayed_webhook/request_unsuccessful'
require 'delayed_webhook/version'
require 'delayed_webhook/hook/base'
require 'delayed_webhook/hook/httparty'

module DelayedWebhook
  class << self
    attr_writer :configuration
  end
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.enqueue!(method, path, options = {})
    configuration.webhook_class.new(method, path, options).enqueue!
  end
end