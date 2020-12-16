# frozen_string_literal: true

require "set"
require "forwardable"
require "libhoney"
require "honeycomb/beeline/version"
require "honeycomb/client"
require "honeycomb/trace"

# main module
module Honeycomb
  INTEGRATIONS = %i[
    active_support
    aws
    faraday
    rack
    rails
    railtie
    rake
    redis
    sequel
    sinatra
  ].freeze

  class << self
    extend Forwardable
    attr_reader :client

    @@integrations_loaded = Set.new

    def_delegators :@client, :libhoney, :start_span, :add_field,
                   :add_field_to_trace, :current_span, :current_trace

    def configure
      Configuration.new.tap do |config|
        yield config
        @client = Honeycomb::Client.new(configuration: config)
      end

      @client
    end

    def load_integrations
      integrations_to_load.each do |integration|
        begin
          require "honeycomb/integrations/#{integration}"
          @@integrations_loaded.add(integration)
        rescue LoadError
        end
      end
    end

    def integrations_loaded
      @@integrations_loaded
    end

    def integrations_to_load
      if ENV["HONEYCOMB_INTEGRATIONS"]
        ENV["HONEYCOMB_INTEGRATIONS"].split(",")
      else
        INTEGRATIONS
      end
    end
  end
end

Honeycomb.load_integrations unless ENV["HONEYCOMB_DISABLE_AUTOCONFIGURE"]
