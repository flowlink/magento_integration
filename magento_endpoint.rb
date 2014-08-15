require "sinatra"
require "endpoint_base"
require "json"

require File.expand_path(File.dirname(__FILE__) + '/lib/magento_integration')

class MagentoEndpoint < EndpointBase::Sinatra::Base

  #endpoint_key ENV["ENDPOINT_KEY"]

  #Honeybadger.configure do |config|
  #  config.api_key = ENV['HONEYBADGER_KEY']
  #  config.environment_name = ENV['RACK_ENV']
  #end if ENV['HONEYBADGER_KEY'].present?
      
  error Savon::SOAPFault do
    result 500, env['sinatra.error'].to_s
  end
  
  before do
    if config = @config
      #TODO
    end
  end
  
  post '/get_orders' do
    order = MagentoIntegration::Order.new(@config);
    orders = order.getOrders
    
    result 200, orders
  end
  
end
