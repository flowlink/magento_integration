# frozen_string_literal: true

module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(config)
      @config = config
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

    private

    def soap_client
      @soap_client ||= MagentoIntegration::Services::Soap.new(@config)
    end
  end
end
