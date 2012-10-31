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

describe 'ignoring rack cascade 404s' do
  let(:logger) { Logger.new(drain) }
  let(:drain) { StringIO.new }

  let(:app) do
    cascade_app = lambda do |env|
      case env['PATH_INFO']
      when '/success'
        [200, default_test_headers, ['success']]
      end
    end

    log = logger
    Rack::Builder.app do
      use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => log
      notfound_app = lambda { |env| [404, default_test_headers, [] ] }
      run Rack::Cascade.new([notfound_app, cascade_app])
    end
  end

  before do
    do_get '/success'
  end

  it_behaves_like 'it logs', 'status', '200'
  it_behaves_like 'it logs', 'url', '/success'

  it 'should not record a 404' do
    drain.should_not include_entry 'status=400'
  end

  it 'should only log one entry' do
    drain.lines.count == 1
  end
end
