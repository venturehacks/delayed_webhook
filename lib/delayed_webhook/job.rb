require 'delayed_webhook/request_unsuccessful'

# Enqueuable job to perform a request, check for success, and retry with exponential backoff.
module DelayedWebhook
  module Job
    def perform
      request = perform_request
      raise DelayedWebhook::RequestUnsuccessful.new(self) unless successful? request
    end

    def max_attempts
      DelayedWebhook.configuration.max_attempts
    end

    def reschedule_at(current_time, attempts)
      current_time + [base_interval * interval_multiplier ** (attempts - 1), max_interval].min
    end

    private

    def base_interval
      DelayedWebhook.configuration.base_interval
    end

    def interval_multiplier
      DelayedWebhook.configuration.interval_multiplier
    end

    def max_interval
      DelayedWebhook.configuration.max_interval
    end

    def successful?(response)
      raise NotImplementedError
    end

    def perform_request
      raise NotImplementedError
    end
  end
end