require 'json'

module MagentoIntegration
  class Product < Base
    
    def add_product(payload, update)
      attribute_set = get_attribute_set
      website = get_store

      wombat_product = {
        :categories => payload[:product][:taxons],
        'website_ids' => [[website[:website_id]]],
        :name => payload[:product][:name],
        :description => payload[:product][:description],
        :status => 2,
        :weight => 0,
        :visibility => 4,
        'tax_class_id' => 2,
        'url_key' => payload[:product][:permalink],
        :price => payload[:product][:price],
        'meta_title' => payload[:product][:meta_title],
        'meta_keyword' => payload[:product][:meta_keywords],
        'meta_description' => payload[:product][:meta_description],
      }

      if payload[:product][:properties]
        attributes = Array.new

        payload[:product][:properties].each do |key, value|
          attributes.push({
            :key => key,
            :value => value
          })
        end
        wombat_product['additional_attributes'] = {
          'single_data' => [attributes]
        }
      end

      if payload[:product][:variants]
        payload[:product][:variants].each do |variant|
          variant_product = wombat_product.clone
          variant_product[:price] = variant[:price].to_f
          if variant[:options]
            attributes = Array.new

            variant[:options].each do |key,value|
              attributes.push({
                :key => key,
                :value => value
              })
            end

            variant_product['additional_attributes'] = {
              'single_data' => [attributes]
            }
          end

          variant_product['stock_data'] = {
            :qty => variant[:quantity],
            'is_in_stock' => (variant[:quantity].to_f > 0) ? 1 : 0,
            'use_config_manage_stock' => 1,
            'use_config_min_qty' => 1,
            'use_config_min_sale_qty' => 1,
            'use_config_max_sale_qty' => 1,
            'use_config_backorders' => 1,
            'use_config_notify_stock_qty' => 1
          }

          if !update
            result = @soapClient.call :catalog_product_create, {
              :type => 'simple',
              :set => attribute_set[:set_id],
              :sku => variant[:sku],
              :product_data => variant_product
            }
            return result.body[:catalog_product_create_response][:result]
          else
            result = @soapClient.call :catalog_product_update, {
                :type => 'simple',
                :product => variant[:sku],
                :product_data => variant_product
            }
            return result.body[:catalog_product_update_response][:result]
          end
        end
      else
        wombat_product['stock_data'] = {
          'use_config_manage_stock' => 1,
          'use_config_min_qty' => 1,
          'use_config_min_sale_qty' => 1,
          'use_config_max_sale_qty' => 1,
          'use_config_backorders' => 1,
          'use_config_notify_stock_qty' => 1
        }
        if payload[:product][:quantity]
          wombat_product['stock_data'][:qty] = payload[:product][:quantity].to_s
          wombat_product['stock_data']['is_in_stock'] = (payload[:product][:quantity].to_f > 0) ? 1 : 0
        end


        if !update
          result = @soapClient.call :catalog_product_create, {
              :type => 'simple',
              :set => attribute_set[:set_id],
              :sku => payload[:product][:id], #product_id will be sku
              :product_data => wombat_product
          }
          return result.body[:catalog_product_create_response][:result]
        else
          result = @soapClient.call :catalog_product_update, {
              :type => 'simple',
              :product => payload[:product][:id], #product_id will be sku
              :product_data => wombat_product
          }
          return result.body[:catalog_product_update_response][:result]
        end

      end

      return true
    end

	def set_inventory(payload)
	  product = {
	    'stock_data' => {
		    :qty => payload[:inventory][:quantity]
		  }
	  }
	  
	  result = @soapClient.call :catalog_product_update, {
      :type => 'simple',
      :product => payload[:inventory][:product_id],
      :product_data => product
    }

	  return result.body[:catalog_product_update_response][:result]
	end
	
    private

    def get_attribute_set
      response = @soapClient.call :catalog_product_attribute_set_list

      attribute_sets = response.body[:catalog_product_attribute_set_list_response][:result][:item]

      if attribute_sets.kind_of?(Array)
        return attribute_sets[0]
      else
        return attribute_sets
      end
    end

    def get_store
      response = @soapClient.call :store_list

      stores = response.body[:store_list_response][:stores][:item]

      if stores.kind_of?(Array)
        return stores[0]
      else
        return stores
      end
    end
  end
end
