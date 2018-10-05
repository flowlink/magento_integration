# frozen_string_literal: true

module MagentoIntegration
  class Base
    attr_reader :soapClient

    def initialize(config)
      @config = config
    end

    # TODO: remove this method from this class, it does not belong here.
    def convert_to_array(object)
      return object if object.is_a?(Array)
      return [object] if object.present?

      []
    end

    private

    def soap_client
      @soap_client ||= MagentoIntegration::Services::Soap.new(@config)
    end
  end
end
