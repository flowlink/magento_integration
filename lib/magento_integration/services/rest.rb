require 'savon'
require 'oauth'
require 'cgi'
require 'mechanize'

module MagentoIntegration
  module Services
    class Rest
      attr_reader :config
      attr_reader :client
      # attr_reader :rest_client
      # attr_reader :c_key
      # attr_reader :c_secret
      # attr_reader :url
      # attr_reader :admin_password
      # attr_reader :admin_username
      attr_accessor :session

      def initialize(config)
        @config = config

        @client = Savon.client(wsdl: "#{@config[:store_url]}/index.php/api/v2_soap?wsdl", :log => false)


        # @c_key = config[:key]
        # @c_secret = config[:secret]
        # @url = config[:store_url]
        # @admin_username = config[:api_username]
        # @admin_password = config[:api_password]
        # @rest_client = get_new_access_tokens

        login
      end

      def create_consumer
        OAuth::Consumer.new(
          c_key,
          c_secret,
          :request_token_path => '/oauth/initiate',
          :authorize_path=>'/admin/oauth_authorize',
          :access_token_path=>'/oauth/token',
          :site => url
        )
      end

      def request_token(args = {})
        args[:consumer].get_request_token(:oauth_callback => url)
      end

      def get_authorize_url(args = {})
        # args[:request_token].authorize_url(:oauth_callback => url)
        args[:request_token].authorize_url()
      end

      def authorize_application(args = {})
        m = Mechanize.new

        m.get(args[:authorize_url]) do |login_page|
          puts login_page
          puts login_page.inspect
          auth_page = login_page.form_with(:action => "#{url}/index.php/admin/oauth_authorize/index/") do |form|
            form.elements[1].value = admin_username
            form.elements[2].value = admin_password
          end.submit

          authorize_form = auth_page.forms[0]

          @callback_page = authorize_form.submit
        end
        puts "callback page: #{@callback_page.uri}"
        @callback_page.uri.to_s
      end

      def extract_oauth_verifier(args = {})
        # callback_page = /https:\/\/[^\/]*\/(.*)/.match("#{args[:callback_page]}")
        # callback_page_query_string = CGI::parse(callback_page[0])
        # puts "CALLBACK Q: #{callback_page_query_string}"

        # callback_page_query_string['oauth_verifier'][0]
        callback_page = /(.*)([?])([o].*)([=])(.*)/.match("#{args[:callback_page]}")
        callback_page
      end

      def get_access_token(args = {})
        begin
          response = args[:request_token].get_access_token(:oauth_verifier => args[:oauth_verifier])
        rescue => exception
          puts exception
          puts exception.inspect
          puts response
        end
        response
      end

      def save_tokens_to_json(args = {})
        auth = {}

        auth[:time] = Time.now
        auth[:token] = args[:access_token].token
        auth[:secret] = args[:access_token].secret

        File.open("#{args[:path]}#{args[:filename]}.json", 'w') {|f| f.write(auth.to_json)}

        auth
      end

      def get_new_access_tokens
        # Create the consumer object
        new_consumer = self.create_consumer
        # Use the consumer object to request a token
        new_request_token = self.request_token(consumer: new_consumer)
        puts "TOKEN: #{new_request_token.inspect}"
        hash = { oauth_token: new_request_token.token, oauth_token_secret: new_request_token.secret}
        # Get the authorize URL
        new_authorize_url = self.get_authorize_url(request_token: new_request_token)
        puts "AUTH URL: #{new_authorize_url}"
        # Fill out the info to authorize the app
        authorize_new_application = self.authorize_application(authorize_url: new_authorize_url)
        # Grab the oauth stuff
        extract_new_oauth_verifier = self.extract_oauth_verifier(callback_page: authorize_new_application)
        puts "OAUTH VERIFIER: #{extract_new_oauth_verifier}"
        new_access_token = self.get_access_token(request_token: new_request_token, oauth_verifier: extract_new_oauth_verifier)
        save_tokens_to_json(filename: 'magento_oauth_access_tokens', path: '/', access_token: new_access_token)

        return 'Successfully obtained new access tokens.'
      end

      # def get_token(config)
      #   new_consumer = OAuth::Consumer.new(
      #     config[:key],
      #     config[:secret],
      #     :request_token_path => '/oauth/initiate',
      #     :authorize_path=>'/admin/oauth_authorize',
      #     :access_token_path=>'/oauth/token',
      #     :site => config[:store_url]
      #   )
      #   new_request_token = new_consumer.get_request_token(:oauth_callback => config[:store_url])
      #   new_authorize_url = new_request_token.authorize_url(:oauth_callback => config[:store_url])
      #   authorize_new_application = authorize_application(new_authorize_url, config[:store_url], config[:api_username], config[:api_password])
      #   extract_new_oauth_verifier = extract_oauth_verifier(authorize_new_application)
      #   new_access_token = get_access_token(request_token: new_request_token, oauth_verifier: extract_new_oauth_verifier)
      # end

      # def authorize_application(new_authorize_url, store_url, username, password)
      #   m = Mechanize.new
      #   m.get(new_authorize_url) do |login_page|
      #     auth_page = login_page.form_with(:action => "#{store_url}/index.php/admin/oauth_authorize/index/") do |form|
      #       form.elements[1].value = username
      #       form.elements[2].value = password
      #     end.submit
      #     authorize_form = auth_page.forms[0]
      #     @callback_page = authorize_form.submit
      #   end
      #   @callback_page.uri.to_s
      # end

      # def extract_oauth_verifier(callback_page)
      #   callback_page = "#{callback_page}".gsub!("#{config[:store_url]}/?", '')
      #   callback_page_query_string = CGI::parse(callback_page)
      #   callback_page_query_string['oauth_verifier'][0]
      # end

      # def get_access_token(args = {})
      #   args[:request_token].get_access_token(:oauth_verifier => args[:oauth_verifier])
      # end

      def login
        response = @client.call(:login, message: { :username => @config[:api_username], :apiKey => @config[:api_key] } )
        # TODO catch access failed

        @session = response.body[:login_response][:login_return]
      end

      def call(method, arguments = {})
        arguments.merge!( :session_id => @session )

        response = @client.call(method, message: arguments )

        return response
      end
    end
  end
end
