require 'spec_helper'
require 'stringio'

describe "logging non success response bodies" do
  let(:logger) { Logger.new(drain) }
  let(:drain) { StringIO.new }

  let(:app) do
    a = lambda do |env|
      case env['PATH_INFO']
      when '/200'
        [200, default_test_headers, ['Success']]
      when '/422'
        [422, default_test_headers, [{'errors' => {'key' => 'val'}}]]
      when '/401'
        [401, default_test_headers, ['Unauthorized']]
      when '/400'
        [400, default_test_headers, ['Fail']]
      when '/500'
        raise "oh noez!"
      end
    end

    log = logger # hold scope out of the block
    Rack::Builder.app do
      use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => log
      run a
    end
  end

  it "should clear the msg attr out after each log line" do
    do_get('/200')
    do_get('/401')
    drain.rewind
    drain.read.scan('method').size.should == 2
  end

  context 'when the proper option is passed in' do
    it "logs the response body for 401's" do
      do_get('/401')
      drain.should include_entry "response_body=.*Unauthorized.*"
    end

    it "logs the response body for 400's" do
      do_get('/400')
      drain.should include_entry "response_body=.*Fail.*"
    end

    it "logs the response body for 422's" do
      do_get('/422')
      drain.should include_entry 'response_body=.*errors.*'
    end
  end

  context 'a 200 response' do
    before do
      do_get('/200')
    end

    it_behaves_like "it logs", 'status', 200

    it 'does not log the response body for success endpoints' do
      drain.should_not include_entry 'response_body=Unauthorized'
    end
  end

  context 'a 400 bad request response' do
    before do
      do_get('/400')
    end

    it_behaves_like 'it logs', 'status', 400
  end

  context 'an unexpected 500 response' do
    before do
      begin
        do_get('/500')
      rescue => e
        # raise other exceptions
        raise e unless e.message == 'oh noez!'
      end
    end

    it_behaves_like 'it logs', 'url', '/500'
    it_behaves_like 'it logs', 'status', 500
  end
end

describe "ignoring certain paths" do
  let(:logger) { Logger.new(drain) }
  let(:drain) { StringIO.new }

  let(:app) do
    ignore_app = lambda do |env|
      case env['PATH_INFO']
      when '/ignore'
        [200, default_test_headers, ['ignore me!']]
      when '/do-not-ignore'
        [200, default_test_headers, ["don't ignore me!"]]
      end
    end

    log = logger
    Rack::Builder.app do
      use Rack::KeyValueLogger, :logger => log, :ignore_paths => /^\/ignore/
      run ignore_app
    end
  end

  it 'does not log anything for ignored paths' do
    do_get('/ignore')
    drain.should_not include_entry "url=/ignore"
  end

  context 'logging non-ignored paths' do
    before do
      do_get '/do-not-ignore'
    end

    it_behaves_like 'it logs', 'status', '200'
    it_behaves_like 'it logs', 'url', '/do-not-ignore'
  end
end