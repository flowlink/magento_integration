# frozen_string_literal: true

require 'oauth'
require 'cgi'
require 'json'

module MagentoIntegration
  module Services
    class Rest
      REST_BASE_PATH = '/api/rest/'

      def initialize(config = {})
        @config = config
        @access_token = generate_access_token
      end

      def get(resource_url, params = {}, options = {})
        url = REST_BASE_PATH + resource_url
        url += '?' + params.to_param if params.any?

        puts url
        puts options

        response_handler { @access_token.get(url, options) }
      end

      def response_handler
        response = yield
        puts @access_token.inspect
        body     = response.body

        return {} unless response.is_a? Net::HTTPSuccess

        return JSON.parse(body) if response.content_type == 'application/json'
        return body.to_hash if body.respond_to?(:to_hash)

        body
      end

      private

      def generate_access_token
        consumer = OAuth::Consumer.new(@config[:key],
                                       @config[:secret],
                                       site: @config[:store_url])
        token_hash = {
          oauth_token: @config[:oauth_token],
          oauth_token_secret: @config[:oauth_token_secret]
        }

        OAuth::AccessToken.from_hash(consumer, token_hash)
      end
    end
  end
end
