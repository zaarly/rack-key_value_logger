require 'logger'
require 'multi_json'

module Rack
  class KeyValueLogger
    SEPARATOR = "|"

    attr_reader :msg, :logger, :opts

    # @param opts
    # @option opts :logger A logger instance
    # @option opts :log_failure_response_bodies
    # @option opts :user_id a string key representing the user id key
    #   in the session hash. Defaults to 'user_id'
    def initialize(app, opts = {})
      @app, @opts = app, opts
      @opts[:logger] ||= ::Logger.new($stdout)
      @logger = @opts[:logger]
      @opts[:log_failure_response_bodies] ||= false
      @opts[:user_id] ||= 'user_id'
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

      # record request attributes
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

        # Don't log Rack::Cascade fake 404's
        return [status, headers, body] if rack_cascade_404?(headers['X-Cascade'])

        record_response_attributes(status, headers, body)
      rescue => e
        msg << 'status=500'
        raise e
      ensure
        record_runtime(start)
        flush_log
      end

      [status, headers, body]
    end

    private
    def record_runtime(start)
      msg << "runtime=#{((Time.now - start) * 1000).round(5)}"
    end

    def flush_log
      result = msg.join(SEPARATOR)
      result = "[#{Time.now.to_i}] " + result

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

    def rack_cascade_404?(cascade_header)
      cascade_header && cascade_header == 'pass'
    end
  end
end
