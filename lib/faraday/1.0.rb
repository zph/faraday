module Faraday
  # Forcefully breaks 0.8.x compatibility in favor of the new CallbackBuilder
  LEGACY = false

  require File.expand_path("..", __FILE__)

  require_lib 'callback_builder'
end

