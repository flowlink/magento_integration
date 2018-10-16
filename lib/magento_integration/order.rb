# frozen_string_literal: true

require 'json'

module MagentoIntegration
  class Order < Base
    def get_orders
      flowlink_orders = []

      # magento_orders = get_rest_orders_since(@config[:since])
      magento_orders = get_orders_since(@config[:since])
      magento_shipments = get_shipments

      magento_orders.each do |magento_order|
        # Get order details
        order = magento_order # get_order_info_by_id(magento_order[:increment_id])

        # Get Customer Info
        customer = get_customer_info_by_customer_id(order[:customer_id])

        # Shipment Info
        shipment = get_shipment_info_by_order_id(order[:order_id], magento_shipments)

        # TODO: build invoice stuff
        # # Invoice Info
        #

        # TODO: Make REST API call here. We need to:
        # 1. Get the coupon code for discounts.
        # ----If no coupon code, we should apply any discounts per line item
        # ----If there is a code, we apply the discount to the whole order

        # Manipulate customer data / make other calls for the customer
        # customer_address_list_response = soap_client.call :customer_address_list, { :customer_id => customer_id }
        # customer_address_list = customer_address_list_response.body[:customer_address_list_response][:result][:item]
        # customer_address_list.each do |c|
        #   customer_address_response = soap_client.call :customer_address_info, { :address_id => c[:customer_address_id] }
        # end

        # customer_address_response = soap_client.call :customer_address_info, { :address_id => order[:billing_address][:address_id] }

        # customer_address_response = soap_client.call :customer_address_info, { :address_id => order[:shipping_address][:address_id] }

        # TODO: Need to build 2 separate objects here:
        # - Invoice Array
        # - Payments Array
        # payments = Array.new

        # order_payments = convert_to_array(order[:payment])
        # payment_method = (order_payments && order_payments.count) ? order_payments[0][:method] : 'no method'

        # puts 'xzxxzxzxzxzxzxzxzxxzxzxzxzzxzxz'
        # puts order[:increment_id]
        # puts order.to_json

        placed_date = Time.parse(order[:created_at]).utc.iso8601
        upated_date = Time.parse(order[:updated_at])
        flownlink_order = {
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
          customer_name: getFullName(order),
          currency: order[:order_currency_code],
          exchange_rate: order[:store_to_order_rate],
          comments: comments(order),
          billing_address: address_magento_to_flowlink(order[:billing_address]),
          shipping_address: address_magento_to_flowlink(order[:shipping_address]),
          updated_at: upated_date.utc.iso8601,
          magento_order_id: order[:order_id],
          shipping_price: order[:shipping_amount],
          email: order[:customer_email],
          discount: order[:discount_amount],
          totals: order_total(order),
          # :payments => payments,
          line_items: order_items(order),
          adjustments: adjustments(order),
          # :total_refunded => order[:total_refunded],
          # :total_due => order[:total_due],
          # :total_qty_ordered => order[:total_qty_ordered],
          # :store_to_base_rate => order[:store_to_base_rate],
          # :weight => order[:weight],
          # :store_name => order[:store_name],
          # :order_state => order[:state],
          # :global_currency_code => order[:global_currency_code],
          # :store_currency_code => order[:store_currency_code],
          # :shipping_description => order[:shipping_description],
          # :is_virtual => order[:is_virtual],
          # :customer_note_notify => order[:customer_note_notify],
          # :customer_is_guest => order[:customer_is_guest],
          # :email_sent => order[:email_sent],
          # :store_id=> order[:store_id],
          # :total_canceled=> order[:total_canceled],
          # :base_tax_amount=> order[:base_tax_amount],
          # :base_shipping_amount=> order[:base_shipping_amount],
          # :base_discount_amount=> order[:base_discount_amount],
          # :base_subtotal=> order[:base_subtotal],
          # :base_grand_total=> order[:base_grand_total],
          # :base_total_canceled=> order[:base_total_canceled],
          # :base_to_global_rate=> order[:base_to_global_rate],
          # :base_to_order_rate=> order[:base_to_order_rate],
          # :base_currency_code=> order[:base_currency_code]
        }

        if soap_client.config[:connection_name]
          flownlink_order[:channel] = soap_client.config[:connection_name]
          flownlink_order[:source] = soap_client.config[:connection_name]
          flownlink_order[:id] = format('%s-%s', soap_client.config[:connection_name], flownlink_order[:id])
        end

        flowlink_orders.push(flownlink_order)
      end

      flowlink_orders
    end

    def get_shipment_objects(orders)
      wombat_shipments = []

      orders.each do |order|
        shipment = {
          id: order[:id],
          order_id: order[:id],
          status: 'ready',
          email: order[:email],
          shipping_method: order[:shipping_method],
          totals: order[:totals],
          items: order[:line_items],
          shipping_address: order[:shipping_address],
          billing_address: order[:billing_address]
        }

        wombat_shipments.push(shipment)
      end

      wombat_shipments
    end

    def cancel_order(payload)
      payload[:order][:id] = remove_connection_name(payload[:order][:id])

      order_response = soap_client.call :sales_order_cancel, order_increment_id: payload[:order][:id]

      order_response.body[:sales_order_cancel_response][:result]
    end

    def add_shipment(payload)
      payload[:shipment][:order_id] = remove_connection_name(payload[:shipment][:order_id])

      order_response = soap_client.call :sales_order_info, order_increment_id: payload[:shipment][:order_id]

      order = order_response.body[:sales_order_info_response][:result]

      items_to_send = []

      order_items = convert_to_array(order[:items][:item])

      order_items.each do |item|
        shipment_items = convert_to_array(payload[:shipment][:items])

        shipment_items.each do |shipped_item|
          next unless shipped_item[:product_id] == item[:sku]

          item_to_send = {
            order_item_id: item[:item_id],
            qty: shipped_item[:quantity].to_f
          }
          items_to_send.push(item_to_send)
          break
        end
      end

      shipment_increment_id = soap_client.call :sales_order_shipment_create,
                                               order_increment_id: payload[:shipment][:order_id],
                                               items_qty: items_to_send,
                                               email: 1

      shipment_increment_id = shipment_increment_id.body[:sales_order_shipment_create_response][:shipment_increment_id]

      carrier_code = false
      shipping_method = payload[:shipment][:shipping_method].downcase
      if shipping_method.include? 'dhl'
        carrier_code = 'dhlint'
      elsif shipping_method.include?('ups') || shipping_method.include?('united parcel service')
        carrier_code = 'ups'
      elsif shipping_method.include?('usps') || shipping_method.include?('united states postal service')
        carrier_code = 'usps'
      elsif shipping_method.include?('fedex') || shipping_method.include?('federal express')
        carrier_code = 'fedex'
      end
      if carrier_code
        soap_client.call :sales_order_shipment_add_track,
                         shipment_increment_id: shipment_increment_id,
                         carrier: carrier_code,
                         title: payload[:shipment][:shipping_method],
                         track_number: payload[:shipment][:tracking]
    end

      if soap_client.config[:connection_name]
        shipment_increment_id = format('%s-%s', soap_client.config[:connection_name], shipment_increment_id)
      end

      shipment_increment_id
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

    def getFullName(order)
      "#{order[:customer_firstname]} #{order[:customer_lastname]}"
    end

    def filters(key, value_key, value_value)
      {
        complex_filter: [[{
          key: key,
          value: {
            key: value_key,
            value: value_value
          }
        }]]
      }
    end

    def get_orders_since(since)
      response = soap_client.call(:sales_order_list,
                                  filters: filters('updated_at', 'from', since))
      convert_to_array(response.body[:sales_order_list_response][:result][:item])
    end

    def get_rest_orders_since(since)
      # TODO: Make filtering work :D
      response = rest_client.get('orders')
    end

    def get_order_info_by_id(increment_id)
      response = soap_client.call(:sales_order_info,
                                  order_increment_id: increment_id)
      response.body[:sales_order_info_response][:result]
    end

    # TODO: Extract this method to a Magento::Customer class
    def get_customer_info_by_customer_id(customer_id)
      response = soap_client.call(:customer_customer_info,
                                  customer_id: customer_id)
      response.body[:customer_customer_info_response][:customer_info]
    end

    def get_shipments
      response = soap_client.call(:sales_order_shipment_list)
      sales_order_shipment_list = response.body[:sales_order_shipment_list_response][:result][:item]
      convert_to_array(sales_order_shipment_list)
    end

    # # TODO: extract this method to a ::Shipment class
    def get_shipment_info_by_order_id(order_id, shipments_list)
      shipments_list.each do |shipment|
        response = soap_client.call(:sales_order_shipment_info, shipment_increment_id: shipment[:increment_id])
        shipment = response.body[:sales_order_shipment_info_response][:result]
        return shipment if shipment[:order_id] == order_id
      end
      {}
    end

    def order_items(order)
      order_items = convert_to_array(order[:items][:item])
      order_items.map do |item|
        item_magento_to_flowlink(item)
      end
    end

    def comments(order)
      comments = []
      hist_items = order[:status_history][:item]
      unless hist_items.nil?
        hist_items = [hist_items] unless hist_items.is_a?(Array)
        hist_items.each do |h|
          comments << h.fetch(:comment, '')
        end
      end
      comments
    end
  end
end
