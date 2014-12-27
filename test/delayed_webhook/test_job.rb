require 'test_helper'

class DelayedWebhook::JobTest < Test::Unit::TestCase
  context nil do
    class Webhook
      include DelayedWebhook::Job
    end

    setup do
      @webhook = Webhook.new
    end

    context '#perform' do
      setup do
        @webhook.stubs(:perform_request).returns(200)
        @webhook.stubs(:successful?).returns(true)
      end
      should 'perform a request' do
        @webhook.expects(:perform_request).once.with()
        @webhook.perform
      end
      should 'check if the request is successful' do
        @webhook.expects(:successful?).once.with(200).returns(true)
        @webhook.perform
      end
      should 'raise an error if the request is not successful' do
        @webhook.stubs(:successful?).returns(false)
        assert_raise DelayedWebhook::RequestUnsuccessful do
          @webhook.perform
        end
      end
    end

    context '#reschedule_at' do
      context 'with custom exponential parameters' do
        setup do
          @webhook.stubs(:base_interval).returns(1)
          @webhook.stubs(:interval_multiplier).returns(2)
          @webhook.stubs(:max_interval).returns(100)
        end

        should 'increase exponentially' do
          current_time = Time.now
          expected_times = [1, 2, 4, 8, 16].map{|interval| current_time + interval}

          expected_times.each_with_index do |time, index|
            attempts = index + 1
            assert_equal time, @webhook.reschedule_at(current_time, attempts)
          end
        end

        should 'respect its maximum interval' do
          current_time = Time.now
          assert_equal (current_time + 100), @webhook.reschedule_at(current_time, 10)
        end
      end

      context 'with a custom global config' do
        should 'use the global config by default' do
          config = DelayedWebhook::Configuration.new
          config.base_interval = 100
          config.interval_multiplier = 5
          config.max_interval = 600
          DelayedWebhook.configuration = config

          current_time = Time.now
          assert_equal (current_time + 500), @webhook.reschedule_at(current_time, 2)
          assert_equal (current_time + 600), @webhook.reschedule_at(current_time, 3)
        end

        teardown do
          DelayedWebhook.configuration = DelayedWebhook::Configuration.new
        end
      end
    end

    context '#max_attempts' do
      should 'respect the global config' do
        DelayedWebhook.configuration.max_attempts = 20
        assert_equal 20, @webhook.max_attempts
      end
      teardown do
        DelayedWebhook.configuration = DelayedWebhook::Configuration.new
      end
    end
  end

  context 'delayed_job integration' do

    # More fully implemented webhook which tracks how many times it's been called by delayed_job
    class IntegrationWebhook
      include DelayedWebhook::Job

      # Tracking across job attempts
      class << self
        attr_accessor :should_succeed, :request_count, :error_count, :failure_count, :success_count, :current_time,
                      :last_reschedule_at

        def reset!
          @should_succeed = true

          @request_count = 0
          @error_count = 0
          @failure_count = 0
          @success_count = 0

          @current_time = Time.now

          @last_reschedule_at = nil
        end
      end

      def perform_request ; self.class.request_count += 1 end
      def successful?(response) ; self.class.should_succeed end

      def error ; self.class.error_count += 1 end
      def failure ; self.class.failure_count += 1 end
      def success ; self.class.success_count += 1 end

      def max_attempts ; 5 end
      def base_interval ; 2 end
      def interval_multiplier ; 3 end
      def max_interval ; 20 end

      def reschedule_at(current_time, attempts)
        ret = super(current_time, attempts)
        self.class.last_reschedule_at = ret
        ret
      end
    end

    setup do
      IntegrationWebhook.reset!
      @webhook = IntegrationWebhook.new
      @worker = Delayed::Worker.new
      assert_equal 0, Delayed::Job.count # Sanity check
    end

    should 'remove if successful' do
      Delayed::Job.enqueue @webhook
      assert_equal 1, Delayed::Job.count

      @worker.work_off 1
      assert_equal 0, Delayed::Job.count
      assert_equal 0, IntegrationWebhook.error_count
      assert_equal 0, IntegrationWebhook.failure_count
      assert_equal 1, IntegrationWebhook.success_count
    end

    should 'retry until success' do
      IntegrationWebhook.should_succeed = false

      Delayed::Job.enqueue @webhook
      assert_equal 1, Delayed::Job.count

      @worker.work_off(1)
      assert_equal 1, IntegrationWebhook.error_count, 'First attempt threw an error'
      assert_equal 0, IntegrationWebhook.failure_count, 'Job has not failed'
      assert_equal 0, IntegrationWebhook.success_count, 'Job has not succeeded'
      assert_equal 1, Delayed::Job.count, 'Job was re-queued'

      IntegrationWebhook.should_succeed = true
      self.db_time_now = IntegrationWebhook.last_reschedule_at

      @worker.work_off(1)
      assert_equal 1, IntegrationWebhook.error_count, 'Job did not error again'
      assert_equal 0, IntegrationWebhook.failure_count, 'Job has not failed'
      assert_equal 1, IntegrationWebhook.success_count, 'Job has succeeded'
      assert_equal 0, Delayed::Job.count, 'Job was removed'
    end

    should 'fail after the specified number of attempts' do
      IntegrationWebhook.should_succeed = false
      Delayed::Job.enqueue @webhook

      1.upto(5).each do |attempt|
        assert_equal 0, IntegrationWebhook.failure_count, 'Job has not yet failed'
        assert_equal 1, Delayed::Job.count, 'Job has been queued'

        @worker.work_off(1)
        assert_equal attempt, IntegrationWebhook.error_count, 'Job has thrown the correct number of errors'
        self.db_time_now = IntegrationWebhook.last_reschedule_at
      end

      assert_equal 0, IntegrationWebhook.success_count, 'Job has not succeed'
      assert_equal 1, IntegrationWebhook.failure_count, 'Job has failed'
      assert_equal 0, Delayed::Job.count, 'Job has been removed'
    end

    should 'reschedule at exponential intervals' do
      IntegrationWebhook.should_succeed = false
      Delayed::Job.enqueue @webhook

      current_time = Time.now
      self.db_time_now = current_time

      @worker.work_off(1)

      intervals = [2, 6, 18, 20]
      intervals.each_with_index do |interval, index|
        total_attempts = index + 1 # Should have been run once at the beginning, plus once for each time this loop was run

        assert_equal total_attempts, IntegrationWebhook.error_count, 'Job has thrown the correct number of errors'
        assert_equal 1, Delayed::Job.count, 'Job is still in the queue'

        current_time += interval - 1
        self.db_time_now = current_time

        @worker.work_off(1)
        assert_equal total_attempts, IntegrationWebhook.error_count, 'Job does not run again when less than an exponential interval has passed'
        assert_equal 1, Delayed::Job.count, 'Job is still in the queue'

        current_time += 1
        self.db_time_now = current_time

        @worker.work_off(1) # The next iteration of the loop should check that the error count is correct
      end

      assert_equal (intervals.count + 1), IntegrationWebhook.error_count, 'Job was run 5 times'
      assert_equal 1, IntegrationWebhook.failure_count, 'Job failed'
    end

    teardown do
      IntegrationWebhook.reset!
    end
  end

  private
  def db_time_now=(db_time_now)
    Delayed::Backend::Test::Job.stubs(:db_time_now).returns(db_time_now)
  end
end