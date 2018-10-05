# frozen_string_literal: true

module MagentoIntegration
  class Base

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

    ## TODO: just allow to soap related configs to go through
    def soap_client
      @soap_client ||= MagentoIntegration::Services::Soap.new(@config)
    end

    # TODO: : just allow to rest related configs to go through
    def rest_client
      @rest_client ||= MagentoIntegration::Services::Rest.new(@config)
    end
  end
end
