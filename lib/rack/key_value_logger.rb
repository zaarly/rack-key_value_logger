require 'logger'

module Rack
  class KeyValueLogger
    SEPARATOR = "|"

    # @param opts
    # @option opts :logger A logger instance
    # @option opts :log_failure_response_bodies
    def initialize(app, opts = {})
      @app, @opts = app, opts
      @opts[:logger] ||= ::Logger.new($stdout)
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
      start = Time.now
      status, headers, body = @app.call(env)

      if headers['X-Cascade'] && headers['X-Cascade'] == 'pass'
        return [status, headers, body]
      end

      logger = @opts[:logger]

      begin
        request        = Rack::Request.new(env)
        user_id        = env['rack.session'] && env['rack.session'][@opts[:user_id]]
        content_length = headers['Content-Length']
        mobile_device  = env['X_MOBILE_DEVICE']
        url            = request.path
        query_string   = env['QUERY_STRING']

        msg = []
        msg << "method=#{request.request_method}"
        msg << "status=#{status}"
        msg << "url=#{url}"
        msg << "params=#{query_string}"
        msg << "user_id=#{user_id}"
        msg << "scheme=#{request.scheme}"
        msg << "content-length=#{content_length}"
        msg << "mobile_device=#{mobile_device}" if mobile_device
        msg << "requested_content_type=#{request.content_type}"
        msg << "content_type=#{headers['Content-Type']}"
        msg << "user_agent=#{request.user_agent}"
        msg << "remote_ip=#{request.ip}"
        msg << "http_version=#{env['HTTP_VERSION']}"
        msg << "runtime=#{((Time.now - start) * 1000).round(5)}"
        msg << "log_source=key_value_logger"

        if status.to_s =~ /^4[0-9]{2}/
          msg << "response_body=#{body}"
        end
        
        result = msg.join(SEPARATOR)
        result = "[#{Time.now.to_i}] " + result

        logger.info result
      rescue => e
        $stderr.puts e
      end
      [status, headers, body]
    end
  end
end
