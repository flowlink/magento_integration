require "sinatra"
require "endpoint_base"
require "json"

require File.expand_path(File.dirname(__FILE__) + '/lib/magento_integration')

class MagentoEndpoint < EndpointBase::Sinatra::Base

  #endpoint_key ENV["ENDPOINT_KEY"]

  Honeybadger.configure do |config|

  end
      
  error Savon::SOAPFault do
    result 500, env['sinatra.error'].to_s
  end
  
  before do

  end
  
  post '/get_orders' do
    begin
      order = MagentoIntegration::Order.new(@config)
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

  post '/add_shipment' do
    begin
      order = MagentoIntegration::Order.new(@config)
      shipment_increment_id = order.add_shipment(@payload)

      shipment = { :id => @payload[:shipment][:id], :magento_shipment_increment_id => shipment_increment_id }
      add_object 'shipment', shipment

      result 200, "The shipment #{@payload[:shipment][:id]} was sent to Magento"
    rescue => e
      result 500, "Unable to send shipment details to Magento. Error: #{e.message}"
    end
  end
  
end
