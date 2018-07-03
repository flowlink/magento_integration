require 'json'

module MagentoIntegration
  class Order < Base
    
    def get_orders(since_time)
      complex_filter = Hash.new
      complex_filter['key'] = "updated_at"
      complex_filter['value'] = {
          :key => "from",
          :value => since_time
      }

      response = @soapClient.call :sales_order_list, {
        :filters => {
          'complex_filter' => [[complex_filter]]
        }
      }

      wombat_orders = Array.new

      orders = response.body

      magento_orders = convert_to_array(orders[:sales_order_list_response][:result][:item])
      magento_orders.each do |order|
        orderResponse = @soapClient.call :sales_order_info, { :order_increment_id => order[:increment_id] }

        order = orderResponse.body[:sales_order_info_response][:result]

        payments = Array.new

        invoices_complex_filter = Hash.new
        invoices_complex_filter['key'] = "order_id"
        invoices_complex_filter['value'] = {
            :key => "eq",
            :value => order[:order_id]
        }

        invoices_response = @soapClient.call :sales_order_invoice_list, {
            :filters => {
                'complex_filter' => [[invoices_complex_filter]]
            }
        }

        invoices = convert_to_array(invoices_response.body[:sales_order_invoice_list_response][:result][:item])

        order_payments = convert_to_array(order[:payment])
        payment_method = (order_payments && order_payments.count) ? order_payments[0][:method] : 'no method'

        i = 1
        invoices.each do |invoice|
          payments.push({
              :number => i,
              :status => get_order_status(order[:status]),
              :amount => invoice[:grand_total].to_f,
              :payment_method => payment_method
          })
          i += 1
        end

        orderTotal = {
          :item => order[:subtotal].to_f,
          :adjustment => order[:subtotal].to_f + order[:tax_amount].to_f + order[:shipping_tax_amount].to_f + order[:discount_amount].to_f,
          :tax => order[:tax_amount].to_f + order[:shipping_tax_amount].to_f,
          :shipping => order[:shipping_amount].to_f,
          :discount => order[:discount_amount].to_f,
          :payment => order[:total_paid].to_f,
          :order => order[:grand_total].to_f
        }

        lineItems = Array.new

        order_items = convert_to_array(order[:items][:item])

        order_items.each do |item|
          lineItems.push(item_m_to_w(item))
        end

        adjustments = Array.new
        adjustments.push({
          :name => 'Tax',
          :tax => orderTotal[:tax]
        })
        adjustments.push({
          :name => 'Shipping',
          :shipping => orderTotal[:shipping]
        })
        adjustments.push({
          :name => 'Discount',
          :discount => orderTotal[:discount]
        })

        placed_date = Time.parse(order[:created_at])
        upated_date = Time.parse(order[:updated_at])

        wombat_order = {
          :id => order[:increment_id],
          :magento_order_id => order[:order_id],
          :status => get_order_status(order[:status]),
          :email => order[:customer_email],
          :currency => order[:order_currency_code],
          :placed_on => placed_date.utc.iso8601,
          :updated_at => upated_date.utc.iso8601,
          :discount => order[:discount_amount],
          :totals => orderTotal,
          :payments => payments,
          :line_items => lineItems,
          :adjustments => adjustments,
          :billing_address => address_m_to_w(order[:billing_address]),
          :shipping_method => order[:shipping_method],
          :total_refunded => order[:total_refunded],
          :total_due => order[:total_due],
          :comments => concat_comments(order[:status_history][:item]),
          :total_qty_ordered => order[:total_qty_ordered],
          :store_to_base_rate => order[:store_to_base_rate],
          :store_to_order_rate => order[:store_to_order_rate],
          :weight => order[:weight],
          :store_name => order[:store_name],
          :order_state => order[:state],
          :global_currency_code => order[:global_currency_code],
          :store_currency_code => order[:store_currency_code],
          :shipping_description => order[:shipping_description],
          :customer_firstname => order[:customer_firstname],
          :customer_lastname => order[:customer_lastname],
          :customer_name => getFullName(order),
          :is_virtual => order[:is_virtual],
          :customer_note_notify => order[:customer_note_notify],
          :customer_is_guest => order[:customer_is_guest],
          :email_sent => order[:email_sent],
          :store_id=> order[:store_id],
          :total_canceled=> order[:total_canceled],
          :base_tax_amount=> order[:base_tax_amount],
          :base_shipping_amount=> order[:base_shipping_amount],
          :base_discount_amount=> order[:base_discount_amount],
          :base_subtotal=> order[:base_subtotal],
          :base_grand_total=> order[:base_grand_total],
          :base_total_canceled=> order[:base_total_canceled],
          :base_to_global_rate=> order[:base_to_global_rate],
          :base_to_order_rate=> order[:base_to_order_rate],
          :base_currency_code=> order[:base_currency_code]
        }

        if @soapClient.config[:connection_name]
          wombat_order[:channel] = @soapClient.config[:connection_name]
          wombat_order[:source] = @soapClient.config[:connection_name]
          wombat_order[:id] = sprintf("%s-%s", @soapClient.config[:connection_name], wombat_order[:id])
        end

        wombat_orders.push(wombat_order)
      end

      wombat_orders
    end
    
    def get_shipment_objects(orders)
      wombat_shipments = Array.new
      
      orders.each do | order |
        shipment = {
          :id => order[:id],
          :order_id => order[:id],
          :status => "ready",
          :email => order[:email],
          :shipping_method => order[:shipping_method],
          :totals => order[:totals],
          :items => order[:line_items],
          :shipping_address => order[:shipping_address],
          :billing_address => order[:billing_address]
        }
        
        wombat_shipments.push(shipment)
      end
      
      return wombat_shipments
    end

    def cancel_order(payload)
      payload[:order][:id] = remove_connection_name(payload[:order][:id])

      order_response = @soapClient.call :sales_order_cancel, { :order_increment_id => payload[:order][:id] }

      order_response.body[:sales_order_cancel_response][:result]
    end

    def add_shipment(payload)
      payload[:shipment][:order_id] = remove_connection_name(payload[:shipment][:order_id])

      order_response = @soapClient.call :sales_order_info, { :order_increment_id => payload[:shipment][:order_id] }

      order = order_response.body[:sales_order_info_response][:result]

      items_to_send = Array.new

      order_items = convert_to_array(order[:items][:item])

      order_items.each do |item|

        shipment_items = convert_to_array(payload[:shipment][:items])

        shipment_items.each do |shipped_item|
          if shipped_item[:product_id] == item[:sku]
            item_to_send = {
                :order_item_id => item[:item_id],
                :qty => shipped_item[:quantity].to_f
            }
            items_to_send.push(item_to_send)
            break
          end
        end
      end

      shipment_increment_id = @soapClient.call :sales_order_shipment_create, {
                            :order_increment_id => payload[:shipment][:order_id],
                            :items_qty => items_to_send,
                            :email => 1
                          }

      shipment_increment_id = shipment_increment_id.body[:sales_order_shipment_create_response][:shipment_increment_id]

      carrier_code = false
      shipping_method = payload[:shipment][:shipping_method].downcase
      if shipping_method.include? 'dhl'
        carrier_code = 'dhlint'
      elsif shipping_method.include? 'ups' or shipping_method.include? 'united parcel service'
        carrier_code = 'ups'
      elsif shipping_method.include? 'usps' or shipping_method.include? 'united states postal service'
        carrier_code = 'usps'
      elsif shipping_method.include? 'fedex' or shipping_method.include? 'federal express'
        carrier_code = 'fedex'
      end
        if carrier_code
          @soapClient.call :sales_order_shipment_add_track, {
              :shipment_increment_id => shipment_increment_id,
              :carrier => carrier_code,
              :title => payload[:shipment][:shipping_method],
              :track_number => payload[:shipment][:tracking]
          }
      end

      if @soapClient.config[:connection_name]
        shipment_increment_id = sprintf("%s-%s", @soapClient.config[:connection_name], shipment_increment_id)
      end

      shipment_increment_id
    end

    private

    def item_m_to_w(item)
      lineItem = {
        :product_id => item[:sku],
        :sku => item[:sku],
        :name => item[:name],
        :quantity => item[:qty_ordered].to_f,
        :price => item[:price].to_f,
        :product_type => item[:product_type],
        :weight => item[:weight],
        :qty_canceled => item[:qty_canceled],
        :qty_invoiced => item[:qty_invoiced],
        :qty_refunded => item[:qty_refunded],
        :qty_shipped => item[:qty_shipped],
        :base_price => item[:base_price],
        :original_price => item[:original_price],
        :base_original_price => item[:base_original_price],
        :tax_percent => item[:tax_percent],
        :tax_amount => item[:tax_amount],
        :base_tax_amount => item[:base_tax_amount],
        :tax_invoiced => item[:tax_invoiced],
        :base_tax_invoiced => item[:base_tax_invoiced],
        :discount_percent => item[:discount_percent],
        :discount_amount => item[:discount_amount],
        :base_discount_amount => item[:base_discount_amount],
        :discount_invoiced => item[:discount_invoiced],
        :base_discount_invoiced => item[:base_discount_invoiced],
        :amount_refunded => item[:amount_refunded],
        :base_amount_refunded => item[:base_amount_refunded],
        :row_total => item[:row_total],
        :base_row_total => item[:base_row_total],
        :row_invoiced => item[:row_invoiced],
        :base_row_invoiced => item[:base_row_invoiced],
        :row_weight => item[:row_weight]
      }

      lineItem
    end

    def address_m_to_w(address)
      addressObject = {
          :firstname => address[:firstname],
          :lastname => address[:lastname],
          :company => address[:company],
          :address1 => address[:street],
          :zipcode => address[:postcode],
          :city => address[:city],
          :state => address[:region],
          :country => address[:country_id],
          :phone => address[:telephone],
          :address_type => address[:address_type]
      }

      addressObject
    end

    def remove_connection_name(string)
      if (@soapClient.config[:connection_name]) && (string.include? "#{@soapClient.config[:connection_name]}-")
        return string["#{@soapClient.config[:connection_name]}-".length, string.length]
      end

      string
    end

    def get_order_status(status)
      case status
        when "processing"
          return "completed"
        when "complete"
          return "completed"
        when "pending_payment"
          return "pending"
        when "payment_review"
          return "payment"
        when "pending_paypal"
          return "pending"
      end
      return status
    end

    def concat_comments(items)
      comments = ""
      unless items.nil?
        items = [items] if !items.kind_of?(Array)
        items.each do |i|
          c = i.fetch(:comment, "")
          comments += "#{c} --- " if c != ""
        end
        comments.chomp!(' --- ')
      end
      comments
    end

    def getFullName(order)
      "#{order[:customer_firstname]} #{order[:customer_lastname]}"
    end
  end
end
