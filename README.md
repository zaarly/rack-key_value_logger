## What

Structured, key-value logging for your rack apps. Inspired by lograge.

## Use It

```ruby
class App < Sinatra::Base
  use Rack::KeyValueLogger
end
```

## TODO

* Allow passing in string or IO object instead of full logger instance. This is probably a performance issue since middlewares get instantiated on every request.