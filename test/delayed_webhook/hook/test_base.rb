require 'test_helper'

class DelayedWebhook::Hook::TestBase < Test::Unit::TestCase
  setup do
    @webhook = DelayedWebhook::Hook::Base.new :get, 'https://google.com', {one: 'two'}
  end
  context '#initialize' do
    should 'store method, path, and options' do
      assert_equal :get, @webhook.request_method
      assert_equal 'https://google.com', @webhook.path
      assert_equal({one: 'two'},  @webhook.options)
    end
  end
  context '#enqueue!' do
    should 'add to the delayed_job queue' do
      assert_equal 0, Delayed::Job.count # Sanity
      @webhook.enqueue!
      assert_equal 1, Delayed::Job.count
    end
    teardown do
      Delayed::Job.delete_all
    end
  end
end