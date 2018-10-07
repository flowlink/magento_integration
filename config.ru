require 'rubygems'
require 'bundler'
require 'pry'
require 'pry-byebug'

Bundler.require(:default)
require "./magento_endpoint"
run MagentoEndpoint
