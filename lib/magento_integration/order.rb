require 'json'

module MagentoIntegration
  class Order < Base

    def initialize(config)
      super(config)
    end
    
    def get_orders
      #shipment_carriers = @soapClient.call :sales_order_shipment_get_carriers, { :order_increment_id => '100000001' }
      #puts shipment_carriers
      response = @soapClient.call :sales_order_list
      
      wombatOrders = Array.new
      
      orders = response.body
      orders[:sales_order_list_response][:result][:item].each do |order|

        orderResponse = @soapClient.call :sales_order_info, { :order_increment_id => order[:increment_id] }

        order = orderResponse.body[:sales_order_info_response][:result]

        orderTotal = {
          :item => order[:subtotal].to_f,
          :tax => order[:tax_amount].to_f + order[:shipping_tax_amount].to_f,
          :shipping => order[:shipping_amount].to_f,
          #todo payment
          :discount => order[:discount_amount].to_f,
          :order => order[:grand_total].to_f
        }
        orderTotal[:adjustments] = orderTotal[:tax] + orderTotal[:shipping] + orderTotal[:discount]

        lineItems = Array.new
        if order[:items][:item].kind_of?(Array)
          order[:items][:item].each do |item|
            lineItems.push(item_m_to_w(item))
          end
        else
          item = order[:items][:item]
          lineItems.push(item_m_to_w(item))
        end

        adjustments = Array.new
        adjustments.push({
          :tax => orderTotal[:tax]
        })
        adjustments.push({
          :shipping => orderTotal[:shipping]
        })
        adjustments.push({
          :discount => orderTotal[:discount]
        })


        wombatOrder = {
          :id => order[:increment_id],
          :magento_order_id => order[:order_id],
          :status => order[:status],
          :email => order[:customer_email],
          :currency => order[:order_currency_code],
          :placed_on => order[:created_at],
          :totals => orderTotal,
          :line_items => lineItems,
          :adjustments => adjustments,
          :billing_address => address_m_to_w(order[:billing_address]),
          :shipping_address => address_m_to_w(order[:shipping_address])
        }

        #payments

        wombatOrders.push(wombatOrder)
      end

      wombatOrders
    end

    def add_shipment(payload)
      order_response = @soapClient.call :sales_order_info, { :order_increment_id => payload[:shipment][:order_id] }

      order = order_response.body[:sales_order_info_response][:result]

      items_to_send = Array.new
      if order[:items][:item].kind_of?(Array)
        order[:items][:item].each do |item|
          payload[:shipment][:items].each do |shipped_item|
            if shipped_item[:product_id] == item[:product_id]
              item_to_send = {
                  :order_item_id => item[:item_id],
                  :qty => shipped_item[:quantity]
              }
              items_to_send.push(item_to_send)
              break
            end
          end
        end
      else
        item = order[:items][:item]
        payload[:shipment][:items].each do |shipped_item|
          if shipped_item[:product_id] == item[:product_id]
            item_to_send = {
                :order_item_id => item[:item_id],
                :qty => shipped_item[:quantity]
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

      return shipment_increment_id[:sales_order_shipment_create_response]
    end

    private

    def item_m_to_w(item)
      lineItem = {
          :product_id => item[:product_id],
          :name => item[:name],
          :quantity => item[:qty_ordered],
          :price => item[:price],
          :product_type => item[:product_type]
      }

      lineItem
    end

    def address_m_to_w(address)
      addressObject = {
          :firstname => address[:firstname],
          :lastname => address[:lastname],
          :address1 => address[:street],
          :zipcode => address[:postcode],
          :city => address[:city],
          :state => address[:region],
          :country => address[:country_id],
          :phone => address[:telephone],
      }

      addressObject
    end
  end
end
