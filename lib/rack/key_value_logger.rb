require 'logger'
require 'multi_json'
require 'active_support/time'

module Rack
  class KeyValueLogger
    SEPARATOR = "|"

    attr_reader :msg, :logger, :opts, :ignore_paths

    # @example Preventing rails assets from being logged
    #   use Rack::KeyValueLogger, :ignore_paths => /\/assets/
    #
    # @example Logging non-success response bodies
    #   use Rack::KeyValueLogger, :log_failure_response_bodies => true
    #   # NOTE: Most fields below have been omitted for brevity and replaced with "..."
    #   # => [1351712789 2012-10-31 19:46:29 UTC] method=GET|url=/422|params=|...|response_body=["{\"errors\"=>{\"key\"=>\"val\"}}"]|runtime=0.07
    #
    # @param opts
    # @option opts :logger A logger instance. Defaults to logging to $stdout.
    # @option opts :log_failure_response_bodies Set to `true` to log response
    #     bodies for non-success codes. Defaults to false.
    # @option opts :user_id a string key representing the user id key.
    #     Defaults to 'user_id'
    # @option opts :ignore_paths a regular expression indicating url paths we don't want to
    #   in the session hash.
    def initialize(app, opts = {})
      @app, @opts = app, opts
      @logger = @opts[:logger] || ::Logger.new($stdout)
      @opts[:log_failure_response_bodies] ||= false
      @opts[:user_id] ||= 'user_id'
      @ignore_paths = @opts[:ignore_paths]
    end

    # Logs key=value pairs of useful information about the request and
    # response to the a log. We either piggy-back off the
    # env['rack.logger'] or we log to $stdout.
    #
    # Components
    #   * session - session hash, json-encoded
    #   * accept - Accept-Encoding request header
    #   * user-agent - User agent string
    #   * request-time - in seconds since epoch
    #   * method - request method
    #   * status - response status code
    #   * url - the url, without query string
    #   * query-string - query string params
    #   * user-id - user's id
    #   * scheme - http or https
    #   * content-length - length in bytes of the response body
    #   * requested-content-type
    #   * content-type - Content-Type response header
    #   * remote-ip - User's ip address
    #   * runtime - Duration of request in milliseconds
    #   * http-version - http version of the client
    #   * mobile-device - the mobile device return by rack-mobile-detect
    def call(env)
      @msg           = []
      start          = Time.now
      request        = Rack::Request.new(env)
      user_id        = env['rack.session'] && env['rack.session'][opts[:user_id]]
      mobile_device  = env['X_MOBILE_DEVICE']
      url            = request.path
      query_string   = env['QUERY_STRING']
      request_id     = env['action_dispatch.request_id'] || env['HTTP_X_REQUEST_ID']

      if ignored_path?(url)
        return @app.call(env)
      end

      # record request attributes
      msg << "ts=#{Time.now.utc.iso8601}"
      msg << "request_id=#{request_id}" if request_id
      msg << "method=#{request.request_method}"
      msg << "url=#{url}"
      msg << "params=#{query_string}"
      msg << "user_id=#{user_id}"
      msg << "scheme=#{request.scheme}"
      msg << "user_agent=#{request.user_agent}"
      msg << "remote_ip=#{request.ip}"
      msg << "http_version=#{env['HTTP_VERSION']}"
      msg << "mobile_device=#{mobile_device}" if mobile_device
      msg << "requested_content_type=#{request.content_type}"
      msg << "log_source=key_value_logger"

      begin
        status, headers, body = @app.call(env)

        record_response_attributes(status, headers, body)
      rescue => e
        msg << 'status=500'
        raise e
      ensure
        record_runtime(start)

        # Don't log Rack::Cascade fake 404's
        flush_log unless rack_cascade_404?(headers)
      end

      [status, headers, body]
    end

    private

    # Returns true if the passed in `url` argument matches the `ignore_paths`
    # attribute. Return false otherwise, or if `ignore_paths` is not set.
    #
    # @param [String] url a url path
    # @return [Boolean]
    def ignored_path?(url)
      return false if ignore_paths.nil?
      url =~ ignore_paths
    end

    def record_runtime(start)
      msg << "runtime=#{((Time.now - start) * 1000).round(5)}"
    end

    # Flush `msg` to the logger instance.
    def flush_log
      result = msg.join(SEPARATOR)
      logger.info result
    end

    def record_response_attributes(status, headers, body)
      msg << "status=#{status}"
      msg << "content-length=#{headers['Content-Length']}"
      msg << "content_type=#{headers['Content-Type']}"

      if status.to_s =~ /^4[0-9]{2}/ && opts[:log_failure_response_bodies]
        response = Rack::Response.new(body, status, headers)
        msg << "response_body=#{MultiJson.encode(response.body)}"
      end
    end

    # Sinatra adds a "X-Cascade" header with a value of "pass" to the response.
    # This makes it possible to detect whether this is a 404 worth logging,
    # or just a Rack::Cascade 404.
    #
    # @param [Hash, nil] headers the headers hash from the response
    # @return [Boolean]
    def rack_cascade_404?(headers)
      return false if headers.nil?
      cascade_header = headers['X-Cascade']
      cascade_header && cascade_header == 'pass'
    end
  end
end
