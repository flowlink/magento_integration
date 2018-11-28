# frozen_string_literal: true

require 'sinatra'
require 'endpoint_base'
require 'json'
require 'honeybadger'
require 'sinatra/reloader'

require File.expand_path(File.dirname(__FILE__) + '/lib/magento_integration')

class MagentoEndpoint < EndpointBase::Sinatra::Base
  # endpoint_key ENV["ENDPOINT_KEY"]
  attr_reader :client

  # Force Sinatra to autoreload this file or any file in the lib directory
  # when they change in development
  configure :development do
    register Sinatra::Reloader
    also_reload './lib/**/*'
    # copy stuff above over from another integration
  end

  Honeybadger.configure do |config|
  end

  error Savon::SOAPFault do
    result 500, env['sinatra.error'].to_s
  end

  before do
  end

  post '/add_order' do
    begin
      order = MagentoIntegration::Order.new(@config)
      status, order_id = product.add_order(@payload)

      if status
        result 200, "Successfully #{status} order #{order_id}"
      else
        result 500, 'Error while trying to send order to Magento'
      end
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to send order to Magento. Error: #{e.message}"
    end
  end

  post '/get_orders' do
    begin
      order = MagentoIntegration::Order.new(@config)
      orders = order.get_orders

      orders.each { |o| add_object 'order', o }

      # if @config[:create_shipment].to_i == 1
      #   shipments = order.get_shipment_objects(orders)
      #   shipments.each { |s| add_object 'shipment', s }
      # end

      line = orders.count.positive? ? "Received #{orders.count} #{'order'.pluralize orders.count} from Magento" : 'No new/updated orders found'

      add_parameter 'since', (orders.count == 50 ? orders.last.updated_at : Time.now.utc.iso8601)

      result 200, line
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to get orders from Magento. Error: #{e.message}"
    end
  end

  post '/get_invoices' do
    begin
      invoices = MagentoIntegration::Invoice.new(@config).get_invoices

      invoices.each { |o| add_object 'invoice', o }

      line = invoices.count.positive? ? "Received #{invoices.count} #{'invoice'.pluralize invoices.count} from Magento" : 'No  new/updated invoices found'

      add_parameter 'since', Time.now.utc.iso8601

      result 200, line
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to get invoices from Magento. Error: #{e.message}"
    end
  end

  post '/cancel_order' do
    begin
      order = MagentoIntegration::Order.new(@config)
      status = order.cancel_order(@payload)

      if status
        result 200, 'Order has been succcessfuly canceled'
      else
        result 500, 'Error while trying to cancel the order'
      end
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to cancel order. Error: #{e.message}"
    end
  end

  post '/add_shipment' do
    begin
      order = MagentoIntegration::Order.new(@config)
      shipment_increment_id = order.add_shipment(@payload)

      shipment = { id: @payload[:shipment][:id], magento_shipment_increment_id: shipment_increment_id }
      add_object 'shipment', shipment

      result 200, "The shipment #{@payload[:shipment][:id]} was sent to Magento"
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to send shipment details to Magento. Error: #{e.message}"
    end
  end

  post '/add_product' do
    begin
      product = MagentoIntegration::Product.new(@config)
      no_products = product.add_product(@payload, false)

      if status
        result 200, "Successfully sent #{no_products} products to Magento store"
      else
        result 500, 'Error while trying to send product(s) to Magento'
      end
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to send product(s) to Magento. Error: #{e.message}"
    end
  end

  post '/update_product' do
    begin
      product = MagentoIntegration::Product.new(@config)
      status = product.add_product(@payload, true)

      if status
        result 200, 'Product successfully updated'
      else
        result 500, 'Error while trying to update product'
      end
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to send product to Magento. Error: #{e.message}"
    end
  end

  post '/set_inventory' do
    begin
      product = MagentoIntegration::Product.new(@config)
      status = product.set_inventory(@payload)

      if status
        result 200, 'Inventory successfully set'
      else
        result 500, 'Error while trying to set inventory'
    end
    rescue StandardError => e
      puts e.backtrace
      result 500, "Unable to set inventory details inside Magento. Error: #{e.message}"
    end
  end
end
