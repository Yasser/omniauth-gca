require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Gca < OmniAuth::Strategies::OAuth2
      class << self
        attr_accessor :gca_sso_token
      end

      option :client_options, {
        :site =>  ENV["GCA_SSO_GATEWAY"],
        :authorize_url => "#{ENV["GCA_SSO_GATEWAY"]}/oauth/authorize",
        :access_token_url => "#{ENV["GCA_SSO_GATEWAY"]}/oauth/token"
      }

      uid { raw_info['uid'] }

      info do
        {
          email: raw_info['email'],
          first_name: raw_info['first_name'],
          last_name: raw_info['last_name'],
          title: raw_info['title'],
          group: raw_info['user_groups']
        }
      end

      extra do
        {
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/user.json").parsed
      end
    end
  end
end

class GcaSsoApi
  def initialize(request_uri, params={})
    @request_uri = request_uri
    @params = params
    @provider_host = OmniAuth::Strategies::Gca.default_options['client_options']['site']
    @client = OAuth2::Client.new(ENV["GCA_SSO_APP_ID"], ENV["GCA_SSO_APP_SECRET"], site: @provider_host, :raise_errors => false)
    @token = @client.client_credentials.get_token
    @response = nil
  end
  
  def get
    @response = token.get(@request_uri)
  end
  
  def post
    @response = token.post(@request_uri, params: @params)
  end
  
  def response
    @response
  end
  
  def token
    @token
  end
end