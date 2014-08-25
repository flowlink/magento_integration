require 'savon'

module MagentoIntegration
  module Services
    class Base
      attr_reader :config
      attr_reader :client
      attr_accessor :session

      def initialize(config)
        @config = config
        
        @client = Savon.client(wsdl: "#{@config[:store_url]}/index.php/api/v2_soap?wsdl", :log => false)

        login
      end
      
      def login
        response = @client.call(:login, message: { :username => @config[:api_username], :apiKey => @config[:api_key] } )
        # TODO catch access failed

        @session = response.body[:login_response][:login_return]
      end
      
      def call(method, arguments = {})
        arguments.merge!( :session_id => @session )

        response = @client.call(method, message: arguments )

        return response
      end
    end
  end
end
