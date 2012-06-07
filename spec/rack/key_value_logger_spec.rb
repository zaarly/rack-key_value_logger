require 'spec_helper'
require 'stringio'

describe "logging non success response bodies" do
  context 'when the proper option is passed in' do
    it "logs the response body for 401's" do
      drain = StringIO.new
      app = Rack::Builder.app do
        use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => Logger.new(drain)

        map '/fail' do
          run lambda { |e| [401, {'Content-Type' => 'text/plain'}, 'Unauthorized'] }
        end
      end

      Rack::MockRequest.new(app).get('/fail')
      drain.rewind
      drain.read.should =~ /response_body=Unauthorized/
    end

    it "logs the response body for 400's" do
      drain = StringIO.new
      app = Rack::Builder.app do
        use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => Logger.new(drain)

        map '/fail' do
          run lambda { |e| [400, {'Content-Type' => 'text/plain'}, 'Unauthorized'] }
        end
      end

      Rack::MockRequest.new(app).get('/fail')
      drain.rewind
      drain.read.should =~ /response_body=Unauthorized/
    end

    it "logs the response body for 422's" do
      drain = StringIO.new
      app = Rack::Builder.app do
        use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => Logger.new(drain)

        map '/fail' do
          run lambda { |e| [422, {'Content-Type' => 'text/plain'}, 'Unauthorized'] }
        end
      end

      Rack::MockRequest.new(app).get('/fail')
      drain.rewind
      drain.read.should =~ /response_body=Unauthorized/
    end

    it 'does not log the response body for success endpoints' do
      drain = StringIO.new
      app = Rack::Builder.app do
        use Rack::KeyValueLogger, :log_failure_response_bodies => true, :logger => Logger.new(drain)

        map '/' do
          run lambda { |e| [200, {'Content-Type' => 'text/plain'}, 'Unauthorized'] }
        end
      end

      Rack::MockRequest.new(app).get('/success')
      drain.rewind
      drain.read.should_not =~ /response_body=Unauthorized/      
    end
  end
end