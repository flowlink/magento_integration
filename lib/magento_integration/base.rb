module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(client)
      
      #@soapClient = MagentoIntegration::Services::Base.new(config);
      @soapClient = client;
    end

    def convert_to_array(object)
      result = Array.new

      if object.kind_of?(Array)
        result = object
      else
        result.push(object)
      end

      return result
    end
  end
end
