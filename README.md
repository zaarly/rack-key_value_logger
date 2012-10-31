[![Build Status](https://secure.travis-ci.org/zaarly/rack-key_value_logger.png)](http://travis-ci.org/zaarly/rack-key_value_logger)

## What

Structured, key-value logging for your rack apps. Inspired by [lograge](https://github.com/roidrage/lograge).

## Why?

Application logs are an incredibly rich source of information. But digging out
the information can be extremely painful if your logs are not structured in an
easily parsable manner.

`Rack::KeyValueLogger` logs key-value pairs, where the key and value are
separated by a "=" character. Pairs are separated by pipe ("|") characters.
Here's an example of what a log line looks like:

```
[1351714706 2012-10-31 20:18:26 UTC] method=GET|url=/homepage|params=page=2|user_id=123|scheme=http|user_agent=curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5|remote_ip=127.0.0.1|http_version=HTTP/1.1|requested_content_type=text/html|log_source=key_value_logger|status=200|content-length=111|content_type=text/html|runtime=21.553
```

## Get Started

```ruby
gem 'rack-key_value_logger'
```

#### Sinatra

```ruby
class MyApp < Sinatra::Base
  use Rack::KeyValueLogger
end
```

#### Rails

```ruby
module MyApp
  class Application < Rails::Application
    # ...
    config.middleware.use "Rack::KeyValueLogger"
  end
end
```

## Configuration

A number of configuration options are supported when adding
`Rack::KeyValueLogger` to the middleware stack.

* `:log_failure_response_bodies` - `true` or `false`. Logs the entire response
  body to the `response_body` key on 40x responses. Defaults to `false`.
* `:ignore_paths` - A regular expression of paths we should not log.
* `:logger` - A `Logger` instance. Defaults to `Logger($stdout)`.
* `:user_id` - A string key at which the current user's id is stored in
  `env["rack.session"]`. Defaults to "user_id".