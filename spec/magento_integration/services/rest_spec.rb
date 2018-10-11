# frozen_string_literal: true

# spec/app_spec.rb

require File.expand_path '../../spec_helper.rb', __dir__

describe MagentoIntegration::Services::Rest do
  let(:valid_config) do
    {
      key: 'valid_rest_key',
      secret: 'valid_rest_secret',
      store_url: 'https://storeurl',
      oauth_token: 'valid_oauth_token',
      oauth_token_secret: 'valid_oauth_token_secret'
    }
  end

  let(:invalid_config) do
    {
      key: 'invalid_rest_key',
      secret: 'invalid_rest_secret',
      store_url: 'https://storeurl',
      oauth_token: 'invalid_oauth_token',
      oauth_token_secret: 'invalid_oauth_token_secret'
    }
  end

  describe '.initialize' do
    context 'when a valid config is provided' do
      it 'instantiates the rest service correctly' do
        @rest_service = MagentoIntegration::Services::Rest.new(valid_config)
        expect(@rest_service.instance_variable_get(:@access_token)).to be_kind_of(OAuth::AccessToken)
      end
    end
  end

  describe '#get orders' do

    context 'when a valid config is provided' do
      let(:rest_service) { @rest_service = MagentoIntegration::Services::Rest.new(valid_config) }

      it 'returns a hash of orders' do
        VCR.use_cassette("rest get orders", record: :new_episodes) do
          orders = rest_service.get('orders')

          expect(orders).to be_kind_of(Hash)
          expect(orders["1"]).to have_key("coupon_code")
        end
      end
    end

    context 'when invalid config is provided' do
      let(:invalid_rest_service) { @rest_service = MagentoIntegration::Services::Rest.new(invalid_config) }

      it 'raises an error' do
        VCR.use_cassette("invalid rest get orders", record: :new_episodes) do
          expect{ invalid_rest_service.get('orders') }.to raise_error
        end
      end
    end
  end
end
