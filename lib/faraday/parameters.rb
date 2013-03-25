require 'forwardable'

module Faraday
  class AbstractParamsEncoder
    attr_reader :utils, :separator

    extend Forwardable
    def_delegators :utils, :escape, :unescape

    def initialize(utils, separator = /[&;] */)
      @utils = utils
      @separator = separator
    end

    def each_pair(query)
      query.split(separator).map do |pair|
        if pair && !pair.empty?
          key, value = pair.split('=', 2)
          key = unescape(key)
          value = unescape(value.to_str) if value.respond_to?(:to_str)
          yield key, value
        end
      end
    end
  end

  class NestedParamsEncoder < AbstractParamsEncoder
    def encode(params)
      return nil if params == nil

      if !params.is_a?(Array)
        if !params.respond_to?(:to_hash)
          raise TypeError,
            "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.kind_of?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort!
      end

      # Helper lambda
      to_query = lambda do |parent, value|
        if value.is_a?(Hash)
          value = value.map do |key, val|
            key = escape(key)
            [key, val]
          end
          value.sort!
          buffer = ""
          value.each do |key, val|
            new_parent = "#{parent}%5B#{key}%5D"
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        elsif value.is_a?(Array)
          buffer = ""
          value.each_with_index do |val, i|
            new_parent = "#{parent}%5B%5D"
            buffer << "#{to_query.call(new_parent, val)}&"
          end
          return buffer.chop
        else
          encoded_value = escape(value)
          return "#{parent}=#{encoded_value}"
        end
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = ''
      params.each do |parent, value|
        encoded_parent = escape(parent)
        buffer << "#{to_query.call(encoded_parent, value)}&"
      end
      return buffer.chop
    end

    def decode(query)
      return nil if query == nil
      params = {}

      each_pair(query) do |key, value|
        array_notation = !!(key =~ /\[\]$/)
        subkeys = key.split(/[\[\]]+/)
        final_subkey = subkeys.pop
        current_hash = params

        for subkey in subkeys
          current_hash = (current_hash[subkey] ||= {})
        end

        if array_notation
          (current_hash[final_subkey] ||= []) << value
        else
          current_hash[final_subkey] = value
        end
      end

      params.each do |key, value|
        params[key] = make_arrays(value) if value.kind_of?(Hash)
      end
      params
    end

    def make_arrays(hash)
      hash.each do |key, value|
        hash[key] = make_arrays(value) if value.kind_of?(Hash)
      end
      if !hash.empty? && hash.keys.all? {|k| k =~ /^\d+$/ }
        hash.sort.inject([]) do |ary, (_, value)|
          ary << value
        end
      else
        hash
      end
    end
  end

  class FlatParamsEncoder < AbstractParamsEncoder
    def encode(params)
      return nil if params == nil

      if !params.is_a?(Array)
        if !params.respond_to?(:to_hash)
          raise TypeError,
            "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash
        params = params.map do |key, value|
          key = key.to_s if key.kind_of?(Symbol)
          [key, value]
        end
        # Useful default for OAuth and caching.
        # Only to be used for non-Array inputs. Arrays should preserve order.
        params.sort!
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      buffer = ''
      params.each do |key, value|
        encoded_key = escape(key)
        value = value.to_s if value == true || value == false
        if value == nil
          buffer << "#{encoded_key}&"
        elsif value.kind_of?(Array)
          value.each do |sub_value|
            encoded_value = escape(sub_value)
            buffer << "#{encoded_key}=#{encoded_value}&"
          end
        else
          encoded_value = escape(value)
          buffer << "#{encoded_key}=#{encoded_value}&"
        end
      end
      return buffer.chop
    end

    def decode(query)
      return nil if query == nil
      params = {}
      each_pair(query) do |key, value|
        prior_value = params[key]
        if prior_value.kind_of?(Array)
          prior_value << value
        elsif prior_value
          params[key] = [prior_value, value]
        else
          params[key] = value
        end
      end
      params
    end
  end
end
