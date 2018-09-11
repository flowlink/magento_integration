require 'json'

module MagentoIntegration
  class Invoice < Base
    attr_reader :magento_invoice
    attr_reader :order
    
    def get_invoices(since_time)
      complex_filter = Hash.new
      complex_filter['key'] = "updated_at"
      complex_filter['value'] = {
          :key => "from",
          :value => since_time
      }

      invoices_response = @soapClient.call :sales_order_invoice_list, {
        :filters => {
            'complex_filter' => [[complex_filter]]
        }
      }

      flowlink_invoices = Array.new
      order_ids = Array.new

      magento_invoices = convert_to_array(invoices_response.body[:sales_order_invoice_list_response][:result][:item])
      magento_invoices.each do |invoice|
        invoiceResponse = @soapClient.call :sales_order_invoice_info, { :invoice_increment_id => invoice[:increment_id] }
        @magento_invoice = invoiceResponse.body[:sales_order_invoice_info_response][:result]

        # Get Order
        orderResponse = @soapClient.call :sales_order_info, { :order_increment_id => @magento_invoice[:order_increment_id] }
        @order = orderResponse.body[:sales_order_info_response][:result]

        flowlink_invoice = to_flowlink_invoice

        if @soapClient.config[:connection_name]
          flowlink_invoice[:channel] = @soapClient.config[:connection_name]
          flowlink_invoice[:source] = @soapClient.config[:connection_name]
          flowlink_invoice[:id] = sprintf("%s-%s", @soapClient.config[:connection_name], flowlink_invoice[:id])
        end

        flowlink_invoices.push(flowlink_invoice)
      end

      flowlink_invoices
    end

    def to_flowlink_invoice
      {
        id: @magento_invoice[:increment_id],
        created_at: Time.parse(@magento_invoice[:created_at]),
        increment_id: @magento_invoice[:increment_id],
        order_id: @magento_invoice[:order_id],
        order_increment_id: @magento_invoice[:order_increment_id],
        # shipping_date: # TODO: ***MR.S specific*** Perhaps we set this shipping date when we move a shipment over?? Otherwise it'll take between 2 and X API calls
        exchange_rate: @order[:store_to_order_rate], # NOTE: ***MR.S specific***
        shipping_amount: @magento_invoice[:shipping_amount],
        comments: build_comments(convert_to_array(@magento_invoice[:comments])),
        payments: build_payments(convert_to_array(@order[:payments])),
        line_items: build_line_items(convert_to_array(@magento_invoice[:items][:item]))
      }
    end

    def build_comments(comments)
      return [] if comments.empty?
      flowlink_comments = Array.new

      comments[0][:item].each do |comment|
        flowlink_comments.push({
          id: comment[:comment_id],
          comment: comment[:comment],
          created_at: Time.parse(comment[:created_at])
        })
      end
      flowlink_comments
    end

    def build_payments(payments)
      return [] if payments.empty?
      flowlink_payments = Array.new
      # payment_method = (payments && payments.count) ? payments[0][:method] : 'no method'
      
      payments[0][:item].each do |payment|
        # TODO: Map payments here
        # flowlink_payments.push(payment)
      end
      flowlink_payments
    end

    def build_line_items(line_items)
      flowlink_line_items = Array.new

      line_items.each do |item|
        flowlink_line_items.push({
          name: item[:name],
          quantity: item[:qty],
          # description: zoho_description # TODO: ***MR.S specific*** Custom field from a product here
          price: item[:price],
          sku: item[:sku],
          item_id: item[:item_id],
          product_id: item[:product_id],
          # discount_amount: # TODO: ***MR.S specific*** If the REST API returns a coupon code, then this is 0, otherwise, we need to use the discount on the item
        })
      end
      flowlink_line_items
    end
  end
end
