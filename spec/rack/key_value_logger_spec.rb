require 'spec_helper'
require 'stringio'

describe "logging non success response bodies" do
  $drain = StringIO.new

  class TestApp < Sinatra::Base
    use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => Logger.new($drain)

    get '/200' do
      'Success'
    end

    get '/422' do
      status 422
      {'errors' => {'key' => 'val'}}
    end

    get '/401' do
      status 401
      'Unauthorized'
    end

    get '/400' do
      status 400
      'Fail'
    end

    get '/500' do
      raise "oh noez!"
    end
  end

  def app
    @app ||= Rack::Builder.app do
      run TestApp
    end
  end

  before do
    $drain.truncate(0) # clear the $drain
  end

  it "should clear the msg attr out after each log line" do
    Rack::MockRequest.new(app).get('/200')
    Rack::MockRequest.new(app).get('/401')
    $drain.rewind
    $drain.read.scan('method').size.should == 2
  end

  context 'when an exception is raised' do
    it "records a log entry" do
      Rack::MockRequest.new(app).get('/400')
      $drain.should include_entry "status=400"
    end
  end

  context 'when the proper option is passed in' do
    it "logs the response body for 401's" do
      Rack::MockRequest.new(app).get('/401')
      $drain.should include_entry "response_body=.*Unauthorized.*"
    end

    it "logs the response body for 400's" do
      Rack::MockRequest.new(app).get('/400')
      $drain.should include_entry "response_body=.*Fail.*"
    end

    it "logs the response body for 422's" do
      res = Rack::MockRequest.new(app).get('/422')
      $drain.should include_entry 'response_body=.*errors.*'
    end

  end

  context 'a 200 response' do
    before do
      Rack::MockRequest.new(app).get('/200')
    end

    it_behaves_like "it logs", 'status', 200

    it 'does not log the response body for success endpoints' do
      $drain.should_not include_entry 'response_body=Unauthorized'
    end
  end

  context 'a 400 bad request response' do
    before do
      Rack::MockRequest.new(app).get('/400')
    end

    it_behaves_like 'it logs', 'status', 400
  end

  context 'an unexpected 500 response' do
    before do
      Rack::MockRequest.new(app).get('/500')
    end

    it_behaves_like 'it logs', 'url', '/500'
    it_behaves_like 'it logs', 'status', 500
  end
end
