# frozen_string_literal: true

require 'json'
require_relative '../utils/hash_tools.rb'

module MagentoIntegration
  class Shipment < Base
    def get_shipments
      magento_shipments = get_shipments_since(@config[:since])
      magento_shipments.map do |magento_shipment|
        shipment_details = get_shipment_details_by_ship_id(magento_shipment[:increment_id])
        magento_shipment = magento_shipment.merge(shipment_details)

        magento_shipment[:shipment_increment_id] = magento_shipment[:increment_id]

        order_details = get_order_info_by_id(magento_shipment[:order_id])
        magento_shipment = magento_shipment.merge(order_details)

        magento_shipment[:tracks] = convert_to_array(magento_shipment[:tracks][:item])
        magento_shipment[:items] = convert_to_array(magento_shipment[:items][:item])
        magento_shipment[:comments] = convert_to_array(magento_shipment[:comments] && magento_shipment[:comments][:item])

        Model.new(magento_shipment).to_flowlink_hash
      end
    end

    class Model
      def initialize(magento_shipment)
        @magento_shipment = magento_shipment
      end

      def to_flowlink_hash
        puts @magento_shipment
        {
          id:               @magento_shipment[:shipment_increment_id],
          magento_id:       @magento_shipment[:shipment_id],
          order_number:     @magento_shipment[:increment_id],
          comments:         @magento_shipment[:comments],
          tracking_numbers: tracking_numbers,
          line_items:       line_items_as_flowlink_hash
        }
      end

      def tracking_numbers
        @magento_shipment[:tracks].map do |track|
          track[:number]
        end
      end

      def line_items_as_flowlink_hash
        @magento_shipment[:items].map do |item|
          {
            sku: item[:sku],
            quantity: item[:qty],
            product_id: item[:product_id]
          }
        end
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

    def get_order_info_by_id(order_id)
      response = soap_client.call(:sales_order_list,
                                  filters('order_id', order_id))
      convert_to_array(
        response.body[:sales_order_list_response][:result][:item]
      ).first
    end

    def get_shipment_details_by_ship_id(increment_id)
      response = soap_client.call(:sales_order_shipment_info,
                                  shipment_increment_id: increment_id)
      body = response.body[:sales_order_shipment_info_response][:result]
      return body if body.is_a?(Hash)

      {}
    end

    def get_shipments_since(since)
      response = soap_client.call(:sales_order_shipment_list,
                                  complex_filters('updated_at', 'from', since))
      convert_to_array(response.body[:sales_order_shipment_list_response][:result][:item])
    end

  end
end
