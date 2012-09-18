require 'rubygems'
require 'rspec'
require 'rack'
require 'sinatra/base'

$:.push(File.expand_path(File.dirname(__FILE__)))
$:.push(File.expand_path(File.dirname(__FILE__)) + '/../lib')

require 'rack-key_value_logger'
require 'rack/key_value_logger'
require 'debugger'

# @example
#   $drain.should include_entry 'status=500'
RSpec::Matchers.define :include_entry do |expected|
  match do |actual|
    actual.rewind
    !!actual.detect { |l| l =~ /#{expected}/ }
  end
end

shared_examples 'it logs' do |field, value|
  it "logs #{field} = #{value}" do
    $drain.should include_entry "#{field}=#{value}"
  end
end

