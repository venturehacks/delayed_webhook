require 'delayed_webhook/hook/httparty'

module DelayedWebhook
  class Configuration
    attr_accessor :max_attempts, :base_interval, :interval_multiplier, :max_interval, :hook_class
    def initialize
      @max_attempts = 10
      @base_interval = 10 * 60 # 10 minutes
      @interval_multiplier = 3
      @max_interval = 24 * 60 * 60 # 1 day
      @hook_class = DelayedWebhook::Hook::HTTParty
    end
  end
end