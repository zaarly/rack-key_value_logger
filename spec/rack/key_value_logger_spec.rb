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
  end

  def app
    @app ||= Rack::Builder.app do
      run TestApp
    end
  end

  context 'when the proper option is passed in' do
    it "logs the response body for 401's" do
      Rack::MockRequest.new(app).get('/401')
      $drain.rewind
      $drain.read.should =~ /response_body=.*Unauthorized.*/
    end

    it "logs the response body for 400's" do
      Rack::MockRequest.new(app).get('/400')
      $drain.rewind
      $drain.read.should =~ /response_body=.*Fail.*/
    end

    it "logs the response body for 422's" do
      res = Rack::MockRequest.new(app).get('/422')
      $drain.rewind
      $drain.read.should =~ /response_body=.*errors.*/
    end

    it 'does not log the response body for success endpoints' do
      Rack::MockRequest.new(app).get('/200')
      $drain.rewind
      $drain.read.should_not =~ /response_body=Unauthorized/
    end
  end
end