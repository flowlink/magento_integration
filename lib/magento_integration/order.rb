# frozen_string_literal: true

require 'json'
require_relative '../utils/hash_tools.rb'

module MagentoIntegration
  class Order < Base
    def add_order(order_payload)
      customer = get_customer_info_by_email(order_payload['email'])
      customer = create_customer(order_payload) unless customer

      ['created', 123]
    end

    def create_customer(order_payload)
       raise 'no customer found'
    end

    def get_orders
      flowlink_orders = []

      magento_orders = get_orders_since(@config[:since])

      magento_orders.first(50).each do |magento_order|
        # Get order details
        order = magento_order
        # If order has status history, it means it is using flowlink
        # magento extension.
        unless magento_order[:status_history]
          order = magento_order.merge(
            get_order_info_by_id(magento_order[:increment_id])
          )
        end


        # Get Customer Info
        customer = get_customer_info_by_customer_id(order[:customer_id])

        #Get shipment info
        shipments = get_shipment_info_by_order_id(magento_order[:order_id])

        placed_date = Time.parse(order[:created_at]).utc.iso8601
        upated_date = Time.parse(order[:updated_at])
        flowlink_order = order.merge({
          created_at: placed_date,
          placed_on: placed_date,
          order_id: order[:order_id],
          order_currency_code: order[:order_currency_code],
          id: order[:increment_id],
          magento_increment_id: order[:increment_id],
          shipping_method: order[:shipping_method],
          store_to_order_rate: order[:store_to_order_rate],
          purchased_from: order[:purchased_from],
          status: order[:status],
          customer_firstname: order[:customer_firstname],
          customer_lastname: order[:customer_lastname],
          customer_name: "#{order[:customer_firstname]} #{order[:customer_lastname]}",
          customer_group: customer && customer[:group_id],
          currency: order[:order_currency_code],
          exchange_rate: order[:store_to_order_rate],
          history_items: order[:status_history] && order[:status_history][:item],
          billing_address: address_magento_to_flowlink(order[:billing_address]),
          shipping_address: address_magento_to_flowlink(order[:shipping_address]),
          updated_at: upated_date.utc.iso8601,
          magento_order_id: order[:order_id],
          shipping_price: order[:shipping_amount],
          email: order[:customer_email],
          discount: order[:discount_amount],
          totals: order_total(order),
          coupon_code: order[:coupon_code],
          # :payments => payments,
          line_items: order_items(order),
          adjustments: adjustments(order),
          total_refunded: order[:total_refunded],
          total_due: order[:total_due],
          total_qty_ordered: order[:total_qty_ordered],
          store_to_base_rate: order[:store_to_base_rate],
          weight: order[:weight],
          store_name: order[:store_name],
          order_state: order[:state],
          global_currency_code: order[:global_currency_code],
          store_currency_code: order[:store_currency_code],
          shipping_description: order[:shipping_description],
          is_virtual: order[:is_virtual],
          customer_note_notify: order[:customer_note_notify],
          customer_is_guest: order[:customer_is_guest],
          email_sent: order[:email_sent],
          store_id: order[:store_id],
          total_canceled: order[:total_canceled],
          base_tax_amount: order[:base_tax_amount],
          base_shipping_amount: order[:base_shipping_amount],
          base_discount_amount: order[:base_discount_amount],
          base_subtotal: order[:base_subtotal],
          base_grand_total: order[:base_grand_total],
          base_total_canceled: order[:base_total_canceled],
          base_to_global_rate: order[:base_to_global_rate],
          base_to_order_rate: order[:base_to_order_rate],
          base_currency_code: order[:base_currency_code],
          shipment_date: shipments.empty? ? nil : shipments.max_by{|h| h[:created_at]}[:created_at],
          shipments: shipments,
          # invoices: invoices
        })

        if soap_client.config[:connection_name]
          flowlink_order[:channel] = soap_client.config[:connection_name]
          flowlink_order[:source] = soap_client.config[:connection_name]
          flowlink_order[:id] = format('%s-%s', soap_client.config[:connection_name], flowlink_order[:id])
        end

        flowlink_orders.push(flowlink_order)
      end

      flowlink_orders
    end

    private

    def item_magento_to_flowlink(item)
      {
        product_id: item[:sku],
        sku: item[:sku],
        name: item[:name],
        quantity: item[:qty_ordered].to_f,
        qty_ordered: item[:qty_ordered].to_f,
        price: item[:price].to_f,
        product_type: item[:product_type],
        weight: item[:weight],
        qty_canceled: item[:qty_canceled],
        qty_invoiced: item[:qty_invoiced],
        qty_refunded: item[:qty_refunded],
        qty_shipped: item[:qty_shipped],
        base_price: item[:base_price],
        original_price: item[:original_price],
        base_original_price: item[:base_original_price],
        tax_percent: item[:tax_percent],
        tax_amount: item[:tax_amount],
        base_tax_amount: item[:base_tax_amount],
        tax_invoiced: item[:tax_invoiced],
        base_tax_invoiced: item[:base_tax_invoiced],
        discount_percent: item[:discount_percent],
        discount_amount: item[:discount_amount],
        base_discount_amount: item[:base_discount_amount],
        discount_invoiced: item[:discount_invoiced],
        base_discount_invoiced: item[:base_discount_invoiced],
        amount_refunded: item[:amount_refunded],
        base_amount_refunded: item[:base_amount_refunded],
        row_total: item[:row_total],
        base_row_total: item[:base_row_total],
        row_invoiced: item[:row_invoiced],
        base_row_invoiced: item[:base_row_invoiced],
        row_weight: item[:row_weight]
      }
    end

    def address_magento_to_flowlink(address)
      {
        firstname: address[:firstname],
        lastname: address[:lastname],
        company: address[:company],
        address1: address[:street],
        zipcode: address[:postcode],
        city: address[:city],
        state: address[:region],
        country: address[:country_id],
        phone: address[:telephone],
        address_type: address[:address_type]
      }
    end

    def remove_connection_name(string)
      if soap_client.config[:connection_name] && (string.include? "#{soap_client.config[:connection_name]}-")
        return string["#{soap_client.config[:connection_name]}-".length, string.length]
      end

      string
    end

    def adjustments(order)
      total = order_total(order)
      [{ name: 'Tax',
         tax: total[:tax] },
       { name: 'Shipping',
         shipping: total[:shipping] },
       { name: 'Discount',
         discount: total[:discount] }]
    end

    def order_total(order)
      {
        item: order[:subtotal].to_f,
        adjustment: order[:subtotal].to_f + order[:tax_amount].to_f + order[:shipping_tax_amount].to_f + order[:discount_amount].to_f,
        tax: order[:tax_amount].to_f + order[:shipping_tax_amount].to_f,
        shipping: order[:shipping_amount].to_f,
        discount: order[:discount_amount].to_f,
        payment: order[:total_paid].to_f,
        order: order[:grand_total].to_f
      }
    end

    def getFullName(order); end

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

    def get_orders_since(since)
      response = soap_client.call(:sales_order_list,
                                  complex_filters('updated_at', 'from', since))
      convert_to_array(response.body[:sales_order_list_response][:result][:item])
    end

    def get_order_info_by_id(increment_id)
      response = soap_client.call(:sales_order_info,
                                  order_increment_id: increment_id)
      response.body[:sales_order_info_response][:result]
    end

    def get_customer_info_by_customer_id(customer_id)
      return unless customer_id

      response = soap_client.call(:customer_customer_info,
                                  customer_id: customer_id)
      response.body[:customer_customer_info_response][:customer_info]
    end

    # TODO: Extract this method to a Magento::Customer class
    def get_customer_info_by_email(email)
      response = soap_client.call(:customer_customer_list,
                                  filters('email', email))


      customer = response.body[:customer_customer_list_response][:store_view] && response.body[:customer_customer_list_response][:store_view][:item]
      return customer if customer

      nil
    end

    def get_shipments
      response = soap_client.call(:sales_order_shipment_list)
      sales_order_shipment_list = response.body[:sales_order_shipment_list_response][:result][:item]
      convert_to_array(sales_order_shipment_list)
    end

    # # TODO: extract this method to a ::Shipment class
    def get_shipment_info_by_order_id(order_id)
      flowlink_shipments = []

      response = soap_client.call(:sales_order_shipment_list, filters('order_id', order_id))
      shipments = response.body[:sales_order_shipment_list_response][:result][:item]
      shipments = convert_to_array(shipments)
      shipments.each do |shipment|
        details = get_shipment_details_by_ship_id(shipment[:increment_id])
        flowlink_shipments << shipment.merge(details)
      end

      flowlink_shipments
    end

    def get_invoice_info_by_order_id(order_id)
      flowlink_invoices = []

      response = soap_client.call(:sales_order_invoice_list, filters('order_id', order_id))
      invoices = response.body[:sales_order_invoice_list_response][:result][:item]
      invoices = convert_to_array(invoices)
      invoices.each do |invoice|
        details = get_invoice_details_by_id(invoice[:increment_id])
        flowlink_invoices << invoice.merge(details)
      end

      flowlink_invoices
    end

    def get_invoice_details_by_id(increment_id)
      response = soap_client.call(:sales_order_invoice_info,
                                  invoice_increment_id: increment_id)
      body = response.body[:sales_order_invoice_info_response][:result]
      return body if body.is_a?(Hash)

      {}
    end

    def get_shipment_details_by_ship_id(increment_id)
      response = soap_client.call(:sales_order_shipment_info,
                                  shipment_increment_id: increment_id)
      body = response.body[:sales_order_shipment_info_response][:result]
      return body if body.is_a?(Hash)

      {}
    end

    def order_items(order)
      order_items = convert_to_array(order[:items][:item])
      order_items.map do |item|
        item_magento_to_flowlink(item)
      end
    end
  end
end
