require 'httparty'
require 'timeout'

module Requester
  class Base

    def initialize(base_path)
      @path = base_path
    end

    protected

    def remote_rws_call(method, path, params)
      begin
        output_log "----remote call #{path}, #{params.inspect}-------"
        response = send(method.to_sym, path, params)
        output_log "--------#{self.class.name} method #{method}, got respnose------"
        output_log response
        return response
      rescue Exception => e
        output_log e
        output_log e.backtrace.join("\n")
        output_log "service call/third party call #{self.class.name} unavailable"
	      return
      end
    end

    def output_log(string)
      if Requester::Base.const_defined?('Rails')
        Rails.logger.error string
      else
        puts string
      end
    end

    def get(path, options={})
      headers = options[:headers]
      timeout = options[:timeout] || @timeout
      if timeout.nil?
        HTTParty.get(path, options.merge(:headers => headers))
      else
        Timeout.timeout(timeout.to_f) do
          HTTParty.get(path, options.merge(:headers => headers))
        end
      end
    end

    def post(path, options={})
      headers = options[:headers]
      timeout = options[:timeout] || @timeout
      if timeout.nil?
        HTTParty.post(path, options.merge(:headers => headers))
      else
        Timeout.timeout(timeout.to_f) do
          HTTParty.post(path, options.merge(:headers => headers))
        end
      end
    end
  end
end
