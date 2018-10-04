# frozen_string_literal: true

# spec/app_spec.rb

require File.expand_path 'spec_helper.rb', __dir__

describe MagentoEndpoint do
  it 'returns success for the health check endpoint' do
    get '/'
    expect(last_response).to be_ok
  end
end
