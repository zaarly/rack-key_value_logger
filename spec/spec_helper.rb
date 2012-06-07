require 'rubygems'
require 'rspec'
require 'rack'
require 'sinatra/base'

$:.push(File.expand_path(File.dirname(__FILE__)))
$:.push(File.expand_path(File.dirname(__FILE__)) + '/../lib')

require 'rack-key_value_logger'
require 'rack/key_value_logger'