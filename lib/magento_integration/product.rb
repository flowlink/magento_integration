# frozen_string_literal: true

require 'json'
require_relative '../utils/hash_tools.rb'

module MagentoIntegration
  class Product < Base
    def get_products
      magento_products = get_products_since(@config[:since])
      magento_products.map do |magento_product|
        product_details = get_product_details_by_id(magento_product[:product_id])
        magento_product = magento_product.merge(product_details)

        magento_product[:product_increment_id] = magento_product[:product_id]

        Model.new(magento_product).to_flowlink_hash
      end
    end

    class Model
      def initialize(magento_product)
        @magento_product = magento_product
      end

      def to_flowlink_hash
        puts @magento_product
        {
          id:               @magento_product[:product_increment_id],
          magento_id:       @magento_product[:product_id]
        }
      end
    end

    private

    # TODO: move this to the soap service
    def complex_filters(key, value_key, value_value)
      {
        filters: {
          '@xsi:type': 'ns1:filters',
          'content!': {
            'complex_filter' => {
              '@SOAP-ENC:arrayType': 'ns1:complexFilter[1]',
              '@xsi:type': 'ns1:complexFilterArray',
              'content!': {
                item: {
                  '@xsi:type': 'ns1:complexFilter',
                  'content!': {
                    key: {
                      '@xsi:type': 'xsd:string',
                      'content!': key
                    },
                    value: {
                      '@xsi:type': 'ns1:associativeEntity',
                      'content!': {
                        key: {
                          '@xsi:type': 'xsd:string',
                          'content!': value_key
                        },
                        value: {
                          '@xsi:type': 'xsd:string',
                          'content!': value_value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    end

    # TODO: move this to the soap service
    def filters(key, value)
      {
        filters: {
          '@xsi:type': 'ns1:filters',
          'content!': {
            'filter' => {
              '@SOAP-ENC:arrayType': 'ns1:associativeEntity[1]',
              '@xsi:type': 'ns1:associativeArray',
              'content!': {
                item: {
                  '@xsi:type': 'ns1:associativeEntity',
                  'content!': {
                    key: {
                      '@xsi:type': 'xsd:string',
                      'content!': key
                    },
                    value: {
                      '@xsi:type': 'xsd:string',
                      'content!': value
                    }
                  }
                }
              }
            }
          }
        }
      }
    end

    def get_product_details_by_id(product)
      response = soap_client.call(:catalog_product_info,
                                  product_id: product)
      body = response.body[:catalog_product_info_response][:result]
      return body if body.is_a?(Hash)

      {}
    end

    def get_products_since(since)
      response = soap_client.call(:catalog_product_list,
                                  complex_filters('updated_at', 'from', since))
      convert_to_array(response.body[:catalog_product_list_response][:store_view][:item])
    end
  end
end
