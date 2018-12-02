# frozen_string_literal: true

require 'json'
require_relative '../utils/hash_tools.rb'

module MagentoIntegration
  class Invoice < Base
    def get_invoices
      magento_invoices = get_invoices_since(@config[:since])
      magento_invoices.map do |magento_invoice|
        invoice_details = get_invoice_details_by_ship_id(magento_invoice[:increment_id])
        magento_invoice = magento_invoice.merge(invoice_details)

        magento_invoice[:invoice_increment_id] = magento_invoice[:increment_id]

        order_details = get_order_info_by_id(magento_invoice[:order_id])
        magento_invoice = magento_invoice.merge(order_details)

        magento_invoice[:items] = convert_to_array(magento_invoice[:items][:item])
        magento_invoice[:comments] = convert_to_array(magento_invoice[:comments] && magento_invoice[:comments][:item])

        Model.new(magento_invoice).to_flowlink_hash
      end
    end

    class Model
      def initialize(magento_invoice)
        @magento_invoice = magento_invoice
      end

      def to_flowlink_hash
        puts @magento_invoice
        {
          id:               @magento_invoice[:invoice_increment_id],
          magento_id:       @magento_invoice[:invoice_id]
        }
      end

      def tracking_numbers
        @magento_invoice[:tracks].map do |track|
          track[:number]
        end
      end

      def line_items_as_flowlink_hash
        @magento_invoice[:items].map do |item|
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

    def get_invoice_details_by_ship_id(increment_id)
      response = soap_client.call(:sales_order_invoice_info,
                                  invoice_increment_id: increment_id)
      body = response.body[:sales_order_invoice_info_response][:result]
      return body if body.is_a?(Hash)

      {}
    end

    def get_invoices_since(since)
      response = soap_client.call(:sales_order_invoice_list,
                                  complex_filters('updated_at', 'from', since))
      convert_to_array(response.body[:sales_order_invoice_list_response][:result][:item])
    end
  end
end
