# frozen_string_literal: true

module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(client)
      # @soapClient = MagentoIntegration::Services::Base.new(config);
      @soapClient = client
    end

    def convert_to_array(object)
      result = []

      if object.is_a?(Array)
        result = object
      elsif !object.nil?
        result.push(object)
      end

      result
    end
  end
end
