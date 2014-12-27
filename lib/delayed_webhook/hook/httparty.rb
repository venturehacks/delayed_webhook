require 'delayed_webhook/hook/base'
require 'httparty'

module DelayedWebhook
  module Hook
    class HTTParty < Base
      include ::HTTParty

      def successful?(response)
        response.code == 200
      end

      def perform_request
        self.class.public_send request_method, path, options
      end

    end
  end
end