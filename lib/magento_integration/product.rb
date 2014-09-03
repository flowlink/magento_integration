require 'json'

module MagentoIntegration
  class Product < Base
    
    def add_product(payload, update)
      attribute_set_id = get_attribute_sets[0][:set_id]
      website_id = get_stores[0][:website_id]

      wombat_product = {
        :categories => payload[:product][:taxons],
        :websites => [website_id],
        :name => payload[:product][:name],
        :description => payload[:product][:description],
        :status => 2,
        :weight => 0,
        :visibility => 4,
        :tax_class_id => 2,
        :url_key => payload[:product][:permalink],
        :price => payload[:product][:price],
        :meta_title => payload[:product][:meta_title],
        :meta_keyword => payload[:product][:meta_keywords],
        :meta_description => payload[:product][:meta_description],
      }

      if payload[:product][:properties]
        attributes = Array.new
        payload[:product][:properties].each do |key,value|
          attributes.push({
            :key => key,
            :value => value
          })
        end
        wombat_product[:additional_attributes] = {
            :single_data => attributes
        }
      end

      if payload[:product][:variants]
        payload[:product][:variants].each do |variant|
          variant_product = wombat_product.clone
          variant_product[:price] = variant[:price].to_f
          if payload[:product][:options]
            attributes = Array.new
            payload[:product][:options].each do |key,value|
              attributes.push({
                :key => key,
                :value => value
              })
            end
            variant_product[:additional_attributes] = {
              :single_data => attributes
            }
          end

          variant_product[:stock_data] = {
            :qty => variant[:quantity].to_f,
            :is_in_stock => (variant[:quantity].to_f > 0) ? 1 : 0,
            :use_config_manage_stock => 1,
            :use_config_min_qty => 1,
            :use_config_min_sale_qty => 1,
            :use_config_max_sale_qty => 1,
            :use_config_backorders => 1,
            :use_config_notify_stock_qty => 1
          }

          if !update
            result = @soapClient.call :catalog_product_create, {
              :type => 'simple',
              :set => attribute_set_id,
              :sku => variant[:sku],
              :product_data => variant_product
            }
          else
            result = @soapClient.call :catalog_product_update, {
                :type => 'simple',
                :product => variant[:sku],
                :product_data => variant_product
            }
          end

          #(result.body[:catalog_product_create_response][:result])
        end
      else
        wombat_product[:stock_data] = {
          :use_config_manage_stock => 1,
          :use_config_min_qty => 1,
          :use_config_min_sale_qty => 1,
          :use_config_max_sale_qty => 1,
          :use_config_backorders => 1,
          :use_config_notify_stock_qty => 1
        }
        if payload[:product][:quantity]
          wombat_product[:stock_data][:qty] = payload[:product][:quantity]
          wombat_product[:stock_data][:is_in_stock] = (payload[:product][:quantity].to_f > 0) ? 1 : 0
        end


        if !update
          result = @soapClient.call :catalog_product_create, {
              :type => 'simple',
              :set => attribute_set_id,
              :sku => payload[:product][:sku],
              :product_data => wombat_product
          }
        else
          result = @soapClient.call :catalog_product_update, {
              :type => 'simple',
              :product => payload[:product][:sku],
              :product_data => wombat_product
          }
        end

        #(result.body[:catalog_product_create_response][:result])
      end

      return true
    end

	def set_inventory(payload)
	  product = {
	    :stock_data => {
		    :qty => payload[:inventory][:quantity]
		}
	  }
	  
	  result = @soapClient.call :catalog_product_update, {
                  :type => 'simple',
                  :product => payload[:inventory][:product_id],
                  :product_data => product
			    }
	  return result
	end
	
    private

    def get_attribute_sets
      response = @soapClient.call :catalog_product_attribute_set_list

      return response.body[:catalog_product_attribute_set_list_response][:result][:item]
    end

    def get_stores
      response = @soapClient.call :store_list

      return response.body[:store_list_response][:stores][:item]
    end
  end
end
