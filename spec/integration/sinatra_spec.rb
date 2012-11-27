require 'spec_helper'

module SinatraTest
  describe 'ignoring rack cascade 404s' do
    DRAIN = StringIO.new
    LOGGER = Logger.new(DRAIN)

    before do
      DRAIN.truncate(0)
    end
    let(:drain) { DRAIN } # for shared helpers

    class Base < Sinatra::Base
      use Rack::KeyValueLogger, :logger => LOGGER
    end

    class FirstApp < Base
      get('/other') { status(200) }
    end

    class SecondApp < Base
      get('/success') { status(200) }
    end

    let(:app) do
      Rack::Builder.app do
        run Rack::Cascade.new([FirstApp, SecondApp])
      end
    end

    before do
      do_get '/success'
    end

    it_behaves_like 'it logs', 'status', '200'
    it_behaves_like 'it logs', 'url', '/success'
    it_behaves_like 'it does not log', 'status', '404'

    it 'should only log one entry' do
      drain.rewind
      drain.lines.count.should == 1
    end
  end
end