module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(config)
      
      @soapClient = MagentoIntegration::Services::Base.new(config);
    end
  end
end
