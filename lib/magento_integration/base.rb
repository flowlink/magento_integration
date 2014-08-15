module MagentoIntegration
  class Base
    attr_accessor :config
    attr_reader :soapClient

    def initialize(config)
      @config = config
      
      @soapClient = MagentoIntegration::Services::Base.new(@config);
    end
  end
end
