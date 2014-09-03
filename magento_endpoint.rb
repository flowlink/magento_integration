require "sinatra"
require "endpoint_base"
require "json"

require File.expand_path(File.dirname(__FILE__) + '/lib/magento_integration')

class MagentoEndpoint < EndpointBase::Sinatra::Base

  #endpoint_key ENV["ENDPOINT_KEY"]
  attr_reader :client

  Honeybadger.configure do |config|

  end
      
  error Savon::SOAPFault do
    result 500, env['sinatra.error'].to_s
  end
  
  before do
  end
  
  post '/get_orders' do
    begin
      order = MagentoIntegration::Order.new(get_client(@config))
      orders = order.get_orders

      orders.each { |o| add_object 'order', o }

      line = if (count = orders.count) > 0
         "Updating #{count} #{"order".pluralize count} from Magento"
      else
         "No orders to import found"
      end

      result 200, line
    rescue => e
      result 500, "Unable to get orders from Magento. Error: #{e.message}"
    end
  end

  post '/cancel_order' do
    begin
      order = MagentoIntegration::Order.new(get_client(@config))
      status = order.cancel_order(@payload)

      if status
        result 200, "Order has been succcessfuly canceled"
      else
        result 500, "Error while trying to cancel the order"
      end
    rescue => e
      result 500, "Unable to get orders from Magento. Error: #{e.message}"
    end
  end

  post '/add_shipment' do
    begin
      order = MagentoIntegration::Order.new(get_client(@config))
      shipment_increment_id = order.add_shipment(@payload)

      shipment = { :id => @payload[:shipment][:id], :magento_shipment_increment_id => shipment_increment_id }
      add_object 'shipment', shipment

      result 200, "The shipment #{@payload[:shipment][:id]} was sent to Magento"
    rescue => e
      result 500, "Unable to send shipment details to Magento. Error: #{e.message}"
    end
  end

  post '/add_product' do
    begin
      product = MagentoIntegration::Product.new(get_client(@config))
      status = product.add_product(@payload, false)

      if status
        result 200, "Product successfully sent to Magento store"
      else
        result 500, "Error while trying to send product to Magento"
      end
    rescue => e
      result 500, "Unable to send product to Magento. Error: #{e.message} #{e.backtrace}"
    end
  end

  post '/update_product' do
    begin
      product = MagentoIntegration::Product.new(get_client(@config))
      status = product.add_product(@payload, true)

      if status
        result 200, "Product successfully updated"
      else
        result 500, "Error while trying to update product"
      end
    rescue => e
      result 500, "Unable to send product to Magento. Error: #{e.message}"
    end
  end
  
  post '/set_inventory' do
    begin
      product = MagentoIntegration::Product.new(get_client(@config))
      status = product.set_inventory(@payload)

      if status
        result 200, "Inventory successfully set"
      else
        result 500, "Error while trying to set inventory"
	  end
    rescue => e
      result 500, "Unable to set inventory details inside Magento. Error: #{e.message}"
    end
  end

  private

  def get_client(config)
    if !@client
      @client = MagentoIntegration::Services::Base.new(config)
    end
    return @client
  end
  
end
