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
          store_url: ENV['URL'],
          api_username: ENV['API_USERNAME'],
          api_password: ENV['API_PASSWORD'],
          api_key: ENV['API_KEY'],
          since: '2017-06-17:21:15Z',
          key: ENV['REST_KEY'],
          secret: ENV['REST_SECRET']
        }
      }.to_json
    end

    context 'with long since param' do
      it 'retrieves the last magento orders correctly' do
        post '/get_orders', post_payload

        expect(last_response).to be_ok
      end
    end
  end
end
