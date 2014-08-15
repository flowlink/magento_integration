require 'json'

module MagentoIntegration
  class Order < Base
    attr_reader :config

    def initialize(config)
      super(config)

      @config = config
    end
    
    def getOrders
      response = @soapClient.call :sales_order_list
      
      wombatOrders = Array.new
      
      orders = response.body
      orders[:sales_order_list_response][:result][:item].each do |order|
      
        orderResponse = @soapClient.call :sales_order_info, { :order_increment_id => order[:increment_id] }
        
        #order = orderResponse.body[:sales_order_info_response][:result]
        
        orderTotal = {
          :item => order[:subtotal].to_f,
          :tax => order[:tax_amount].to_f + order[:shipping_tax_amount].to_f,
          :shipping => order[:shipping_amount].to_f,
          # TODO order payed amount
          :discount => order[:discount_amount].to_f,
          :order => order[:grand_total].to_f
        }
        orderTotal[:adjustments] = orderTotal[:tax] + orderTotal[:shipping] + orderTotal[:discount]
        
        lineItems = Array.new
        
        
        wombatOrder = {
          :id => order[:order_id],
          :status => order[:status],
          :email => order[:customer_email],
          :currency => order[:order_currency_code],
          :placed_on => order[:created_at],
          :totals => orderTotal,
          :line_items => lineItems
        }
        
        wombatOrders.push(wombatOrder)
      end
      
      return wombatOrders
      
    rescue Exception => e
      return { :error => e.message }
    end
  end
end
