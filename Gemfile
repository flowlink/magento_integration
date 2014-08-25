source 'https://www.rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'savon', '~> 2.0'

gem 'endpoint_base', github: 'spree/endpoint_base'
gem 'capistrano'

gem 'honeybadger'

group :development do
  gem 'rake', '~> 10.3.2'
end

group :test do
  gem 'rspec', '~> 2.14'
  gem 'rack-test'
  gem 'webmock'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end
