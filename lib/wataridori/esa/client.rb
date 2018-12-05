# frozen_string_literal: true

require 'esa'

module Wataridori
  module Esa
    # Esa::Clientのwrapper
    # リトライやリクエストレートの制御などを行う
    class Client
      def initialize(access_token:, current_team:)
        @original = ::Esa::Client.new(access_token: access_token, current_team: current_team)
        @ratelimit = Ratelimit.no_wait
      end

      private

      attr_reader :original, :ratelimit

      def method_missing(method_name, *args)
        return call_original(method_name, *args) if original.respond_to?(method_name)

        super
      end

      def call_original(method_name, *args)
        sleep ratelimit.second_for_next_request
        original.send(method_name, *args).yield_self do |response|
          @ratelimit = Ratelimit.from_headers(response.headers)
          Wataridori::Esa::Response.new(response.body)
        end
      end

      def respond_to_missing?(method_name, *)
        original.respond_to?(method_name) || super
      end
    end
  end
end
