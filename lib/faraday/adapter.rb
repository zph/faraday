module Faraday
  module Adapter
    module Methods
      def self.included(adapter)
        adapter.send :attr_accessor, :builder
      end

      def call(req)
        @builder.on_request(req)

        res = if @builder.streaming_callbacks?
          streaming_response(req)
        else
          response(req)
        end

        @builder.on_response(res)

        res
      end
    end
  end
end

