source 'https://www.rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'savon', '~> 2.0'
gem 'oauth'
gem 'mechanize'
gem 'rubyntlm', '~> 0.3.2'

gem 'jbuilder', '2.0.6'
gem 'endpoint_base', github: 'flowlink/endpoint_base'

gem 'honeybadger'
gem 'airbrake'

gem 'sinatra-contrib' # For sinatra/reloader which autoreloads modules on change

group :development do
  gem 'rake'
  gem 'shotgun'
end

group :test do
  gem 'vcr'
  gem 'webmock'
  gem 'rspec', '~> 2.14'
  gem 'rack-test'
  gem 'simplecov', require: false
end

group :test, :development do
  gem 'pry'
  gem 'pry-byebug'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end
