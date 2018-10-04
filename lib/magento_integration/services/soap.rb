# frozen_string_literal: true

require 'savon'
require 'oauth'
require 'cgi'
require 'mechanize'

module MagentoIntegration
  module Services
    class Soap
      attr_reader :config
      attr_reader :client
      attr_accessor :session

      def initialize(config)
        @config = config
        @session = login
      end

      def login
        response = client.call(:login, message: { username: @config[:api_username], apiKey: @config[:api_key] })
        # TODO: catch access failed

        response.body[:login_response][:login_return]
      end

      def call(method, arguments = {})
        arguments[:session_id] = @session

        response = client.call(method, message: arguments)

        response
      end

      private

      def client
        @client ||= Savon.client(wsdl: "#{@config[:store_url]}/index.php/api/v2_soap?wsdl", log: false)
      end
    end
  end
end
