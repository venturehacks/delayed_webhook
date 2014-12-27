require 'delayed_webhook/job'
require 'delayed_job'

module DelayedWebhook
  module Hook
    class Base
      include DelayedWebhook::Job

      attr_accessor :request_method, :path, :options

      def initialize(request_method, path, options = {})
        @request_method = request_method
        @path = path
        @options = options
      end

      def enqueue!
        Delayed::Job.enqueue self
      end
    end
  end
end