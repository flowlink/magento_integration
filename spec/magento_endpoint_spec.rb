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
      it 'retrieves the last magento orders correctly' do
        VCR.use_cassette("post get_orders", record: :new_episodes) do
          post '/get_orders', post_payload

          expect(last_response).to be_ok
        end
      end
    end
  end
end
