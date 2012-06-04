require 'rubygems'
require 'rspec'
require 'rack'

$:.push(File.expand_path(File.dirname(__FILE__)))
$:.push(File.expand_path(File.dirname(__FILE__)) + '/../lib')

require 'key-value-logger'
require 'rack/key_value_logger'