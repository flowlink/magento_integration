# frozen_string_literal: true

# spec/app_spec.rb

require File.expand_path 'spec_helper.rb', __dir__

describe MagentoEndpoint do
  it 'returns success for the health check endpoint' do
    get '/'
    expect(last_response).to be_ok
  end

  describe 'POST /get_orders', type: :request do
    let(:post_payload) do
      {
        request_id: '123456',
        parameters: {
          store_url: 'https://storeurl',
          api_username: 'nurelm',
          api_password: 'valid_api_password',
          api_key: 'valid_api_key',
          since: '2017-06-17:21:15Z',
          key: 'valid_rest_key',
          secret: 'valid_rest_secret'
        }
      }.to_json
    end

    context 'with long since param' do
      it 'retrieves the last magento orders without errors' do
        VCR.use_cassette('post get_orders', record: :new_episodes) do
          post '/get_orders', post_payload

          expect(last_response).to be_ok
        end
      end

      it 'retrieves all attributes it has to' do
        VCR.use_cassette('post get_orders', record: :new_episodes) do
          post '/get_orders', post_payload

          first_order = JSON.parse(last_response.body)['orders'][0]
          first_line_item = first_order['line_items'][0]

          expect(first_order).to include('created_at')
          expect(first_order).to include('order_id')
          expect(first_order).to include('status')
          expect(first_order).to include('customer_firstname')
          expect(first_order).to include('customer_lastname')
          expect(first_order).to include('order_currency_code')
          expect(first_order).to include('shipping_method')
          expect(first_order).to include('store_to_order_rate')
          expect(first_order).to include('comments')
          expect(first_order).to include('billing_address')
          expect(first_order).to include('shipping_address')
          expect(first_order).to include('updated_at')
          expect(first_order).to include('magento_order_id')
          expect(first_order).to include('purchased_from')
          expect(first_order).to include('shipping_price')
          expect(first_order).to include('line_items')
          # expect(first_order).to include('sales_representative')

          expect(first_line_item).to include('name')
          expect(first_line_item).to include('qty_ordered')
          expect(first_line_item).to include('price')
          # expect(line_items).to include('discount_amount')
          # expect(line_items).to include('zoho_description')
        end
      end
    end
  end
end
