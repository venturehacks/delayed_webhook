[![Build Status](https://travis-ci.org/venturehacks/delayed_webhook.svg?branch=master)](https://travis-ci.org/venturehacks/delayed_webhook)

delayed_webhook
===============

Trigger webhook callbacks, and retry until they're successfully processed.

## Basic Usage

Use `DelayedWebhook.enqueue!` to run a webhook for your application:

```
method = :get # HTTP method to use (must be supported by HTTParty)
path = ... # Webhook target, passed as the first argument to the method above
options = { ... } # HTTParty options, passed as the second argument to the method above
DelayedWebhook.enqueue! method, path, options
```

The `enqueue!` method adds the webhook to your `delayed_job` queue, and runs it repeatedly, at exponentially-increasing
intervals, until a successful response (HTTP code 200) is received.

## Configuration

Use `DelayedWebhook.configure` to set global behavior defaults:

```
DelayedWebhook.configure do |config|
  config.max_attempts = 20 # Number of tries before treating the webhook as failed. Defaults to 10.
  config.base_interval = 30 # Initial interval, in seconds, between request attempts. The interval increases exponentially after each failed attempt. Defaults to 10 minutes.
  config.interval_multiplier = 2 # Exponent base for the exponential backoff algorithm - e.g. 2 causes the interval between attempts to double each time a request fails. Defaults to 3.
  config.max_interval = 3600 # Maximum interval, in seconds, between request attempts. Defaults to 1 day.
  config.hook_class = ApplicationWebhook # Class to instantiate with DelayedWebhook.enqueue!. Defaults to DelayedWebhook::Hook::HTTParty
end
```

Each of these options can also be configured at the class level:

```
class ApplicationWebhook < DelayedWebhook::Hook::HTTParty
  def max_attempts
    5
  end
end
```

## Advanced Usage

You can subclass `DelayedWebhook::Hook::HTTParty` and configure your subclass as you would anything including `HTTParty`. You
can also override any `delayed_job` [hooks](https://github.com/collectiveidea/delayed_job#hooks) for e.g. error
handling:

```
class ApplicationWebhook < DelayedWebhook::Hook::HTTParty
  headers {'User-Agent' => 'my webhook user agent'}
  def error(job, exception)
    # Handle failed attempt
  end
  def failure(job)
    # Handle max attempts reached
  end
end
ApplicationWebhook.new(:post, 'http://webhook/target', {}).enqueue
```

You can also include `DelayedWebhook::Job` directly for alternative HTTP request implementations. You just need to
implement `perform_request` and `successful?`, and then add your object to your `delayed_job` queue:

```
class ApplicationWebhook
  include DelayedWebhook::Job
  private
  def perform_request
    # Custom HTTP logic, return the request
  end
  def successful?(request)
    # Receives the request from #perform_request, returns true or false
  end
end
Delayed::Job.enqueue ApplicationWebhook.new
```