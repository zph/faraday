require 'forwardable'

module Faraday
  class Response
    extend Forwardable

    def self.from_env(env)
      new.apply_env(env)
    end

    attr_reader :status, :headers, :body

    def initialize(status = nil, headers = nil, body = nil)
      @status = status
      @headers = headers
      @body = body
      @on_complete_callbacks = []
    end

    attr_reader :env

    def_delegator :headers, :[]

    def on_complete
      if finished?
        yield env
        apply_env(env)
      else
        @on_complete_callbacks << Proc.new
      end

      self
    end

    def finished?
      @status
    end

    def finish(env)
      raise "response already finished" if finished?
      env = Env.from(env)
      @on_complete_callbacks.each { |callback| callback.call(env) }
      apply_env(env)
    end

    def success?
      finished? && env.success?
    end

    # Expand the env with more properties, without overriding existing ones.
    # Useful for applying request params after restoring a marshalled Response.
    def apply_request(request_env)
      raise "response didn't finish yet" unless finished?
      apply_env Env.from(request_env).merge(@env)
    end

    def apply_env(env)
      @env = env
      @status = env.status
      @body = env.body
      @headers = env.response_headers
      self
    end

    def marshal_dump
      {:status => @status, :body => @body, :response_headers => @headers}
    end

    def marshal_load(hash)
      apply_env Env.from(hash)
    end

    alias to_hash marshal_dump
  end
end

