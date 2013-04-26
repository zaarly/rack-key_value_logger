# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "key_value_logger/version"

Gem::Specification.new do |s|
  s.name        = "rack-key_value_logger"
  s.version     = Rack::KeyValueLogger::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alex Sharp"]
  s.email       = ["ajsharp@gmail.com"]
  s.homepage    = "https://github.com/zaarly/rack-key_value_logger"
  s.summary     = %q{Structured, key-value logging for your rack apps.}
  s.description = %q{Structured, key-value logging for your rack apps. Inspired by lograge.}

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'multi_json'
  s.add_dependency 'rack'
  s.add_dependency 'activesupport'
end
