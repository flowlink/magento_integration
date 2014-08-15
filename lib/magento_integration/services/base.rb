require 'savon'

module MagentoIntegration
  module Services
    class Base
      attr_reader :config
      attr_reader :client
      attr_reader :session

      def initialize(config)
        @config = config
        
        @client = Savon.client(wsdl: "http://127.0.0.1/magento/index.php/api/v2_soap?wsdl")
        
        login
      end
      
      def login
        response = @client.call(:login, message: { :username => 'wombat', :apiKey => 'p@ssw0rd' } )
        # TODO catch access failed

        @session = response.body[:login_response][:login_return];
      end
      
      def call(method, arguments = {})
        arguments[:session] = @session
      
        response = @client.call(method, message: arguments )
        
        return response;
      end
    end
  end
end
