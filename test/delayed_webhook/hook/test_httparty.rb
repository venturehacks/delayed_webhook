require 'test_helper'

class DelayedWebhook::Hook::TestHTTParty < Test::Unit::TestCase
  setup do
    @webhook = DelayedWebhook::Hook::HTTParty.new :post, 'http://www.google.com', headers: {'X-test-header' => '1'}
  end
  context '#perform_request' do
    setup do
      stub_request :any, 'http://www.google.com'
    end
    should 'send a request' do
      @webhook.perform_request
      assert_requested :post, 'http://www.google.com', headers: {'X-test-header' => '1'}, times: 1
    end

    should 'allow changing the request type' do
      @webhook.request_method = :get
      @webhook.perform_request
      assert_requested :get, 'http://www.google.com', headers: {'X-test-header' => '1'}, times: 1
    end
  end

  context '#successful?' do
    should 'return true on HTTP code 200' do
      stub_request(:post, 'http://www.google.com').to_return(status: 200)
      assert @webhook.successful?(HTTParty.post('http://www.google.com'))
    end

    should 'return false on HTTP code other than 200' do
      stub_request(:post, 'http://www.google.com').to_return(status: 404)
      assert_false @webhook.successful?(HTTParty.post('http://www.google.com'))
    end
  end

  context 'integration' do
    context '#perform' do
      should 'raise an exception on an unsuccessful reqeust' do
        stub_request(:post, 'http://www.google.com').to_return(status: 500)
        assert_raise DelayedWebhook::RequestUnsuccessful do
          @webhook.perform
        end
      end
      should 'not raise an exception on a successful request' do
        stub_request(:post, 'http://www.google.com').to_return(status: 200)
        assert_nothing_raised do
          @webhook.perform
        end
      end
    end
  end
end