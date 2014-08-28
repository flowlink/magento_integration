module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(client)
      
      #@soapClient = MagentoIntegration::Services::Base.new(config);
      @soapClient = client;
    end
  end
end
